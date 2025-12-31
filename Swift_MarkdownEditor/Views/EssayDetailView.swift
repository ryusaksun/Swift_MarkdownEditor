//
//  EssayDetailView.swift
//  Swift_MarkdownEditor
//
//  Created by Ryuichi on 2025/12/31.
//

import SwiftUI
import WebKit

/// Essay 详情视图 - 纯黑极简风格
struct EssayDetailView: View {
    let essay: Essay
    @Environment(\.dismiss) private var dismiss
    
    // 样式常量
    private let metaColor = Color(hex: "#6B7280")
    
    var body: some View {
        ZStack {
            // 纯黑背景
            Color.black
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 0) {
                // 元数据行
                HStack(spacing: 8) {
                    Text("Ryuichi")
                        .font(.caption)
                        .foregroundColor(metaColor)
                    
                    Text(essay.webFormattedDate)
                        .font(.caption)
                        .foregroundColor(metaColor)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                // Markdown 内容
                EssayMarkdownWebView(content: essay.content)
                    .padding(.horizontal, 4)
            }
        }
        .navigationTitle(essay.title ?? "随笔")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

// MARK: - Markdown WebView

/// 用于渲染 Markdown 内容的 WebView - 纯黑风格
struct EssayMarkdownWebView: UIViewRepresentable {
    let content: String
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let html = generateHTML(content: content)
        webView.loadHTMLString(html, baseURL: nil)
    }
    
    private func generateHTML(content: String) -> String {
        // 转义内容中的特殊字符
        let escapedContent = content
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`", with: "\\`")
            .replacingOccurrences(of: "$", with: "\\$")
        
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>
            <style>
                * {
                    box-sizing: border-box;
                    -webkit-tap-highlight-color: transparent;
                }
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', 'Helvetica Neue', sans-serif;
                    font-size: 16px;
                    line-height: 1.75;
                    color: #FFFFFF;
                    background-color: #000000;
                    padding: 16px;
                    margin: 0;
                    word-wrap: break-word;
                    -webkit-font-smoothing: antialiased;
                }
                h1, h2, h3, h4, h5, h6 {
                    margin-top: 1.5em;
                    margin-bottom: 0.5em;
                    font-weight: 600;
                    color: #FFFFFF;
                }
                h1 { font-size: 1.5em; }
                h2 { font-size: 1.3em; }
                h3 { font-size: 1.1em; }
                p {
                    margin: 1em 0;
                    color: #FFFFFF;
                }
                a {
                    color: #60A5FA;
                    text-decoration: none;
                }
                img {
                    max-width: 100%;
                    height: auto;
                    border-radius: 8px;
                    margin: 1em 0;
                    display: block;
                }
                code {
                    font-family: 'SF Mono', Menlo, Monaco, monospace;
                    font-size: 0.9em;
                    background-color: #1a1a1a;
                    color: #E5E5E5;
                    padding: 2px 6px;
                    border-radius: 4px;
                }
                pre {
                    background-color: #1a1a1a;
                    padding: 16px;
                    border-radius: 8px;
                    overflow-x: auto;
                    -webkit-overflow-scrolling: touch;
                }
                pre code {
                    background: none;
                    padding: 0;
                }
                blockquote {
                    margin: 1em 0;
                    padding-left: 16px;
                    border-left: 3px solid #6B7280;
                    color: #9CA3AF;
                }
                ul, ol {
                    padding-left: 24px;
                    color: #FFFFFF;
                }
                li {
                    margin: 0.5em 0;
                }
                hr {
                    border: none;
                    border-top: 1px solid #333333;
                    margin: 2em 0;
                }
            </style>
        </head>
        <body>
            <div id="content"></div>
            <script>
                document.getElementById('content').innerHTML = marked.parse(`\(escapedContent)`);
            </script>
        </body>
        </html>
        """
    }
}

#Preview {
    NavigationStack {
        EssayDetailView(essay: Essay(
            fileName: "test.md",
            title: "测试随笔",
            pubDate: Date(),
            content: "# 这是标题\n\n这是正文内容，包含一些 **粗体** 和 *斜体* 文字。\n\n![图片](https://example.com/image.jpg)",
            rawContent: ""
        ))
    }
}
