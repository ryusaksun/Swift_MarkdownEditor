//
//  Theme.swift
//  Swift_MarkdownEditor
//
//  Created by Ryuichi on 2025/12/26.
//

import SwiftUI
import Combine

// MARK: - 主题类型

enum AppTheme: String, CaseIterable {
    case slate = "slate"      // 深蓝灰主题（当前）
    case oled = "oled"        // 纯黑 OLED 主题
    
    var displayName: String {
        switch self {
        case .slate: return "深蓝"
        case .oled: return "纯黑"
        }
    }
    
    var icon: String {
        switch self {
        case .slate: return "moon.fill"
        case .oled: return "circle.fill"
        }
    }
}

// MARK: - 主题管理器

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "app_theme")
        }
    }
    
    private init() {
        let savedTheme = UserDefaults.standard.string(forKey: "app_theme") ?? AppTheme.slate.rawValue
        self.currentTheme = AppTheme(rawValue: savedTheme) ?? .slate
    }
    
    func toggle() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentTheme = currentTheme == .slate ? .oled : .slate
        }
    }
}

// MARK: - 主题颜色

struct ThemeColors {
    let bgBody: Color
    let bgSurface: Color
    let bgSurfaceHover: Color
    let textMain: Color
    let textSecondary: Color
    let textMuted: Color
    let borderColor: Color
    let borderColorLight: Color
    
    // 深蓝灰主题
    static let slate = ThemeColors(
        bgBody: Color(hex: "#0f172a"),
        bgSurface: Color(hex: "#1e293b"),
        bgSurfaceHover: Color(hex: "#334155"),
        textMain: Color(hex: "#f1f5f9"),
        textSecondary: Color(hex: "#94a3b8"),
        textMuted: Color(hex: "#64748b"),
        borderColor: Color(hex: "#334155"),
        borderColorLight: Color(hex: "#475569")
    )
    
    // 纯黑 OLED 主题
    static let oled = ThemeColors(
        bgBody: Color(hex: "#000000"),
        bgSurface: Color(hex: "#0a0a0a"),
        bgSurfaceHover: Color(hex: "#1a1a1a"),
        textMain: Color(hex: "#ffffff"),
        textSecondary: Color(hex: "#a0a0a0"),
        textMuted: Color(hex: "#666666"),
        borderColor: Color(hex: "#1a1a1a"),
        borderColorLight: Color(hex: "#2a2a2a")
    )
    
    static func current(_ theme: AppTheme) -> ThemeColors {
        switch theme {
        case .slate: return .slate
        case .oled: return .oled
        }
    }
}

// MARK: - 环境键

private struct ThemeColorsKey: EnvironmentKey {
    static let defaultValue: ThemeColors = .slate
}

extension EnvironmentValues {
    var themeColors: ThemeColors {
        get { self[ThemeColorsKey.self] }
        set { self[ThemeColorsKey.self] = newValue }
    }
}

// MARK: - 兼容旧代码的静态颜色

extension Color {
    
    // MARK: - 背景色（使用动态主题）
    
    /// 主背景色
    static var bgBody: Color {
        ThemeColors.current(ThemeManager.shared.currentTheme).bgBody
    }
    
    /// 表面背景色
    static var bgSurface: Color {
        ThemeColors.current(ThemeManager.shared.currentTheme).bgSurface
    }
    
    /// 悬停表面背景色
    static var bgSurfaceHover: Color {
        ThemeColors.current(ThemeManager.shared.currentTheme).bgSurfaceHover
    }
    
    // MARK: - 文字颜色
    
    /// 主文字颜色
    static var textMain: Color {
        ThemeColors.current(ThemeManager.shared.currentTheme).textMain
    }
    
    /// 次要文字颜色
    static var textSecondary: Color {
        ThemeColors.current(ThemeManager.shared.currentTheme).textSecondary
    }
    
    /// 弱化文字颜色
    static var textMuted: Color {
        ThemeColors.current(ThemeManager.shared.currentTheme).textMuted
    }
    
    // MARK: - 边框颜色
    
    /// 边框颜色
    static var borderColor: Color {
        ThemeColors.current(ThemeManager.shared.currentTheme).borderColor
    }
    
    /// 浅边框颜色
    static var borderColorLight: Color {
        ThemeColors.current(ThemeManager.shared.currentTheme).borderColorLight
    }
    
    // MARK: - 主题色（不变）
    
    /// 主题色 - 克莱因蓝 International Klein Blue #002FA7
    static let primaryBlue = Color(hex: "#002FA7")
    
    /// 渐变起始色
    static let primaryGradientStart = Color(hex: "#002FA7")
    
    /// 渐变结束色
    static let primaryGradientEnd = Color(hex: "#001f6a")
    
    // MARK: - 状态颜色（不变）
    
    /// 成功色
    static let successGreen = Color(hex: "#10b981")
    
    /// 警告色
    static let warningOrange = Color(hex: "#f59e0b")
    
    /// 错误色
    static let errorRed = Color(hex: "#ef4444")
    
    // MARK: - 初始化方法
    
    /// 从十六进制字符串创建颜色
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - 主题样式常量

struct ThemeStyle {
    
    // MARK: - 圆角
    
    /// 小圆角 --radius-sm: 6px
    static let radiusSm: CGFloat = 6
    
    /// 中圆角 --radius-md: 12px
    static let radiusMd: CGFloat = 12
    
    /// 大圆角 --radius-lg: 16px
    static let radiusLg: CGFloat = 16
    
    /// 全圆角 --radius-full: 9999px
    static let radiusFull: CGFloat = 9999
    
    // MARK: - 间距
    
    /// 小间距
    static let spacingSm: CGFloat = 8
    
    /// 中间距
    static let spacingMd: CGFloat = 16
    
    /// 大间距
    static let spacingLg: CGFloat = 24
    
    // MARK: - 动画
    
    /// 标准动画时长
    static let animationDuration: Double = 0.3
    
    /// 弹性动画
    static let springAnimation = Animation.spring(response: 0.3, dampingFraction: 0.7)
}

// MARK: - 渐变

extension LinearGradient {
    /// 主题渐变
    static let primaryGradient = LinearGradient(
        gradient: Gradient(colors: [Color.primaryGradientStart, Color.primaryGradientEnd]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
