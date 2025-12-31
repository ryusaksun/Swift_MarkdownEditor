//
//  Swift_MarkdownEditorApp.swift
//  Swift_MarkdownEditor
//
//  Created by Ryuichi on 2025/12/26.
//

import SwiftUI

@main
struct Swift_MarkdownEditorApp: App {
    
    init() {
        // 初始化本地配置（从 LocalConfig 加载 Token）
        LocalConfig.initializeIfNeeded()
        
        // 预热 WebView（后台异步执行，不阻塞启动）
        Task { @MainActor in
            WebViewPreloader.shared.warmUp()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
    }
}
