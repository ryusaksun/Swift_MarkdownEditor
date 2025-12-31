//
//  MainTabView.swift
//  Swift_MarkdownEditor
//
//  Created by Ryuichi on 2025/12/31.
//

import SwiftUI

/// 主 TabBar 视图
struct MainTabView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 编辑器 Tab
            ContentView()
                .tabItem {
                    Image(systemName: "square.and.pencil")
                }
                .tag(0)
            
            // Essays Tab
            EssaysListView()
                .tabItem {
                    Image(systemName: "book.fill")
                }
                .tag(1)
            
            // 设置 Tab
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                }
                .tag(2)
        }
        .tint(.primaryBlue)
        .onAppear {
            // 自定义 TabBar 外观
            configureTabBarAppearance()
        }
        .onChange(of: themeManager.currentTheme) { _, _ in
            configureTabBarAppearance()
        }
    }
    
    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        
        // 根据主题设置颜色
        let bgColor: UIColor
        let itemColor: UIColor
        // 克莱因蓝 #002FA7 = RGB(0, 47, 167)
        let selectedColor = UIColor(red: 0/255.0, green: 47/255.0, blue: 167/255.0, alpha: 1.0)
        
        switch themeManager.currentTheme {
        case .slate:
            bgColor = UIColor(red: 0.06, green: 0.09, blue: 0.16, alpha: 1.0)
            itemColor = UIColor(white: 0.6, alpha: 1.0)
        case .oled:
            bgColor = .black
            itemColor = UIColor(white: 0.5, alpha: 1.0)
        }
        
        appearance.backgroundColor = bgColor
        
        // 正常状态
        appearance.stackedLayoutAppearance.normal.iconColor = itemColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.clear,
            .font: UIFont.systemFont(ofSize: 0)
        ]
        
        // 选中状态
        appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.clear,
            .font: UIFont.systemFont(ofSize: 0)
        ]
        
        // 紧凑布局
        appearance.compactInlineLayoutAppearance.normal.iconColor = itemColor
        appearance.compactInlineLayoutAppearance.selected.iconColor = selectedColor
        appearance.inlineLayoutAppearance.normal.iconColor = itemColor
        appearance.inlineLayoutAppearance.selected.iconColor = selectedColor
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

#Preview {
    MainTabView()
}

