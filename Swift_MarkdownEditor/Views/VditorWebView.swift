//
//  VditorWebView.swift
//  Swift_MarkdownEditor
//
//  Created by Ryuichi on 2025/12/26.
//

import SwiftUI
import WebKit

/// 自定义 WKWebView 子类，隐藏键盘辅助工具条
class NoInputAccessoryWebView: WKWebView {
    override var inputAccessoryView: UIView? {
        return nil
    }
}

/// Vditor 编辑器 WebView 封装
struct VditorWebView: UIViewRepresentable {
    @Binding var content: String
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        
        // 添加消息处理器
        configuration.userContentController.add(context.coordinator, name: "editorReady")
        configuration.userContentController.add(context.coordinator, name: "contentChanged")
        
        // 根据当前主题设置初始 CSS 变量
        let currentTheme = ThemeManager.shared.currentTheme
        let bgColor = currentTheme == .oled ? "#000000" : "#1e293b"
        let textColor = currentTheme == .oled ? "#ffffff" : "#f1f5f9"
        
        let initialThemeScript = WKUserScript(
            source: """
            (function() {
                document.documentElement.style.setProperty('--theme-bg', '\(bgColor)');
                document.documentElement.style.setProperty('--theme-text', '\(textColor)');
            })();
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        configuration.userContentController.addUserScript(initialThemeScript)
        
        // 使用自定义 WebView（无键盘辅助条）
        let webView = NoInputAccessoryWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        
        // 根据当前主题设置 WebView 背景色
        let themeBgColor = ThemeColors.current(currentTheme).bgSurface
        webView.backgroundColor = UIColor(themeBgColor)
        webView.scrollView.backgroundColor = UIColor(themeBgColor)
        webView.navigationDelegate = context.coordinator
        
        // 加载 HTML
        if let htmlPath = Bundle.main.path(forResource: "editor", ofType: "html") {
            let htmlUrl = URL(fileURLWithPath: htmlPath)
            webView.loadFileURL(htmlUrl, allowingReadAccessTo: htmlUrl.deletingLastPathComponent())
        }
        
        context.coordinator.webView = webView
        VditorManager.shared.webView = webView
        VditorManager.shared.coordinator = context.coordinator
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // 内容同步由 JavaScript 回调处理
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    /// 清理 WebView 资源（修复内存泄漏）
    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        // 标记已清理，防止 deinit 重复调用
        coordinator.markCleanedUp()
        
        // 移除消息处理器，防止内存泄漏
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "editorReady")
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "contentChanged")
        webView.stopLoading()
        webView.navigationDelegate = nil
        coordinator.webView = nil
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: VditorWebView
        weak var webView: WKWebView?
        var isReady = false
        private var isCleanedUp = false
        
        init(_ parent: VditorWebView) {
            self.parent = parent
        }
        
        deinit {
            // 确保清理（仅当 dismantleUIView 未被调用时）
            guard !isCleanedUp else { return }
            webView?.configuration.userContentController.removeAllScriptMessageHandlers()
        }
        
        /// 标记已清理（由 dismantleUIView 调用）
        func markCleanedUp() {
            isCleanedUp = true
        }
        
        // MARK: - WKScriptMessageHandler
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            switch message.name {
            case "editorReady":
                isReady = true
                // 立即应用当前主题（避免启动时闪烁）
                VditorManager.shared.setTheme(ThemeManager.shared.currentTheme)
                // 设置初始内容
                if !parent.content.isEmpty {
                    setContent(parent.content)
                }
                // 自动聚焦并弹出键盘（快速响应）
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    self?.webView?.becomeFirstResponder()
                    // 同时从 JavaScript 端聚焦
                    self?.webView?.evaluateJavaScript("focusEditor();", completionHandler: nil)
                }
                
            case "contentChanged":
                if let content = message.body as? String {
                    DispatchQueue.main.async { [weak self] in
                        self?.parent.content = content
                    }
                }
                
            default:
                break
            }
        }
        
        // MARK: - 设置内容
        
        func setContent(_ content: String) {
            guard isReady else { return }
            let escaped = content
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "'", with: "\\'")
                .replacingOccurrences(of: "\n", with: "\\n")
                .replacingOccurrences(of: "\r", with: "")
            webView?.evaluateJavaScript("setContent('\(escaped)')") { _, _ in }
        }
        
        // MARK: - 插入图片
        
        func insertImage(url: String, alt: String = "image") {
            guard isReady else { return }
            let escaped = url.replacingOccurrences(of: "'", with: "\\'")
            webView?.evaluateJavaScript("insertImage('\(escaped)', '\(alt)')") { _, _ in }
        }
    }
}

/// 全局 Vditor 管理器
/// 使用 @MainActor 确保所有 UI 操作在主线程执行
@MainActor
class VditorManager {
    static let shared = VditorManager()
    
    weak var webView: WKWebView?
    weak var coordinator: VditorWebView.Coordinator?
    
    private init() {}
    
    func insertImage(url: String) {
        coordinator?.insertImage(url: url)
    }
    
    func clearContent() {
        coordinator?.setContent("")
    }
    
    /// 主动获取 WebView 中的最新内容
    func getContent() async -> String {
        guard let webView = webView else { return "" }
        
        do {
            let result = try await webView.evaluateJavaScript("getContent()")
            return result as? String ?? ""
        } catch {
            print("获取内容失败: \(error)")
            return ""
        }
    }
    
    /// 切换编辑器主题
    func setTheme(_ theme: AppTheme) {
        let bgColor: String
        let textColor: String
        
        switch theme {
        case .slate:
            bgColor = "#1e293b"
            textColor = "#f1f5f9"
        case .oled:
            bgColor = "#000000"
            textColor = "#ffffff"
        }
        
        // 使用 CSS 变量更新主题
        let js = """
        (function() {
            document.documentElement.style.setProperty('--theme-bg', '\(bgColor)');
            document.documentElement.style.setProperty('--theme-text', '\(textColor)');
        })();
        """
        
        webView?.evaluateJavaScript(js) { _, error in
            if let error = error {
                print("设置主题失败: \(error)")
            }
        }
    }
}
