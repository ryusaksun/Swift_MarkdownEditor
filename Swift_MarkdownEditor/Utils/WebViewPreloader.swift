//
//  WebViewPreloader.swift
//  Swift_MarkdownEditor
//
//  Created by Ryuichi on 2025/12/31.
//

import WebKit
import SwiftUI

/// WebView 预加载器
/// 在 App 启动时预热 WebView，消除首次加载延迟
@MainActor
class WebViewPreloader {
    
    // MARK: - 单例
    
    static let shared = WebViewPreloader()
    
    // MARK: - 属性
    
    /// 预加载的 WebView 实例
    private var preloadedWebView: WKWebView?
    
    /// 预加载完成的配置
    private var preloadedConfiguration: WKWebViewConfiguration?
    
    /// 是否已预加载完成
    private(set) var isWarmedUp = false
    
    // MARK: - 初始化
    
    private init() {}
    
    // MARK: - 预加载
    
    /// 预热 WebView
    /// 在 App 启动时调用，提前加载 HTML 和 JavaScript
    func warmUp() {
        guard preloadedWebView == nil else { return }
        
        print("🔥 开始预热 WebView...")
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // 创建配置
        let configuration = WKWebViewConfiguration()
        
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
        
        // 创建 WebView
        let webView = NoInputAccessoryWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        
        // 设置背景色
        let themeBgColor = ThemeColors.current(currentTheme).bgSurface
        webView.backgroundColor = UIColor(themeBgColor)
        webView.scrollView.backgroundColor = UIColor(themeBgColor)
        
        // 加载 HTML
        if let htmlPath = Bundle.main.path(forResource: "editor", ofType: "html") {
            let htmlUrl = URL(fileURLWithPath: htmlPath)
            webView.loadFileURL(htmlUrl, allowingReadAccessTo: htmlUrl.deletingLastPathComponent())
        }
        
        preloadedWebView = webView
        preloadedConfiguration = configuration
        isWarmedUp = true
        
        let elapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
        print("✅ WebView 预热完成 (\(String(format: "%.1f", elapsed))ms)")
    }
    
    /// 获取预加载的 WebView
    /// - Returns: 预加载的 WebView，获取后会清空缓存（一次性使用）
    func getPreloadedWebView() -> WKWebView? {
        guard let webView = preloadedWebView else { return nil }
        
        // 一次性使用，清空缓存
        preloadedWebView = nil
        preloadedConfiguration = nil
        isWarmedUp = false
        
        print("📦 使用预加载的 WebView")
        return webView
    }
    
    /// 获取预加载的配置（用于创建新 WebView 时复用）
    func getPreloadedConfiguration() -> WKWebViewConfiguration? {
        return preloadedConfiguration
    }
}
