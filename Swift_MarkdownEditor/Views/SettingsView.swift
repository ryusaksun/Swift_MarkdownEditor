//
//  SettingsView.swift
//  Swift_MarkdownEditor
//
//  Created by Ryuichi on 2025/12/31.
//

import SwiftUI

/// 设置页面视图
struct SettingsView: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) private var colorScheme
    
    // GitHub Token
    @State private var githubToken: String = ""
    @State private var isTokenVisible: Bool = false
    @State private var isVerifying: Bool = false
    @State private var verificationResult: VerificationResult?
    
    // 仓库配置
    @State private var githubOwner: String = ""
    @State private var githubRepo: String = ""
    @State private var githubBranch: String = ""
    
    // 图床配置
    @State private var imageRepo: String = ""
    @State private var cdnType: String = "jsdelivr"
    
    // 缓存
    @State private var cacheSize: String = "计算中..."
    @State private var showClearCacheAlert: Bool = false
    
    enum VerificationResult {
        case success(String)
        case failure(String)
    }
    
    private let cdnOptions = ["jsdelivr", "statically", "raw"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 外观设置
                    appearanceSection
                    
                    // GitHub Token 配置
                    githubTokenSection
                    
                    // 仓库配置
                    repoConfigSection
                    
                    // 图床配置
                    imageConfigSection
                    
                    // 缓存管理
                    cacheSection
                    
                    // 关于
                    aboutSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .background(Color.bgBody)
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.bgBody, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .onAppear {
            loadSettings()
            calculateCacheSize()
        }
        .onChange(of: colorScheme) { _, newScheme in
            themeManager.updateSystemColorScheme(newScheme)
        }
        .alert("清除缓存", isPresented: $showClearCacheAlert) {
            Button("取消", role: .cancel) { }
            Button("清除", role: .destructive) {
                clearCache()
            }
        } message: {
            Text("确定要清除所有本地缓存吗？这将删除 Essays 缓存数据。")
        }
    }
    
    // MARK: - 外观设置
    
    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("外观")
            
            VStack(spacing: 0) {
                ForEach(AppTheme.allCases, id: \.rawValue) { theme in
                    themeRow(theme)
                    
                    if theme != .auto {
                        Divider()
                            .background(Color.borderColor)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: ThemeStyle.radiusMd)
                    .fill(Color.bgSurface)
            )
        }
    }
    
    private func themeRow(_ theme: AppTheme) -> some View {
        Button {
            HapticManager.impact(.light)
            withAnimation(.easeInOut(duration: 0.2)) {
                themeManager.currentTheme = theme
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: theme.icon)
                    .font(.system(size: 18))
                    .foregroundColor(themeManager.currentTheme == theme ? .primaryBlue : .textSecondary)
                    .frame(width: 28)
                
                Text(theme.displayName)
                    .font(.system(size: 15))
                    .foregroundColor(.textMain)
                
                Spacer()
                
                if themeManager.currentTheme == theme {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primaryBlue)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - GitHub Token 配置
    
    private var githubTokenSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("GitHub Token")
            
            VStack(spacing: 12) {
                // Token 输入框
                HStack(spacing: 12) {
                    if isTokenVisible {
                        TextField("输入 GitHub Token", text: $githubToken)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundColor(.textMain)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                    } else {
                        SecureField("输入 GitHub Token", text: $githubToken)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundColor(.textMain)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                    }
                    
                    Button {
                        isTokenVisible.toggle()
                    } label: {
                        Image(systemName: isTokenVisible ? "eye.slash.fill" : "eye.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: ThemeStyle.radiusSm)
                        .fill(Color.bgSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: ThemeStyle.radiusSm)
                                .stroke(Color.borderColor, lineWidth: 1)
                        )
                )
                
                // 验证结果
                if let result = verificationResult {
                    HStack(spacing: 8) {
                        switch result {
                        case .success(let message):
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.successGreen)
                            Text(message)
                                .foregroundColor(.successGreen)
                        case .failure(let error):
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.errorRed)
                            Text(error)
                                .foregroundColor(.errorRed)
                        }
                    }
                    .font(.system(size: 13))
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // 保存和验证按钮
                HStack(spacing: 12) {
                    Button {
                        saveToken()
                    } label: {
                        Text("保存")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.textMain)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: ThemeStyle.radiusSm)
                                    .fill(Color.bgSurfaceHover)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(githubToken.isEmpty)
                    .opacity(githubToken.isEmpty ? 0.6 : 1)
                    
                    Button {
                        saveAndVerifyToken()
                    } label: {
                        HStack(spacing: 6) {
                            if isVerifying {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.7)
                            }
                            Text("保存并验证")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: ThemeStyle.radiusSm)
                                .fill(Color.primaryBlue)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(githubToken.isEmpty || isVerifying)
                    .opacity(githubToken.isEmpty ? 0.6 : 1)
                }
            }
            
            Text("Token 将安全存储在设备 Keychain 中")
                .font(.system(size: 12))
                .foregroundColor(.textMuted)
        }
    }
    
    // MARK: - 仓库配置
    
    private var repoConfigSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("仓库配置")
            
            VStack(spacing: 12) {
                configInputRow(title: "Owner", placeholder: "GitHub 用户名", text: $githubOwner)
                configInputRow(title: "Repo", placeholder: "仓库名称", text: $githubRepo)
                configInputRow(title: "Branch", placeholder: "分支名称", text: $githubBranch)
                
                HStack(spacing: 12) {
                    Button {
                        saveRepoConfig()
                    } label: {
                        Text("保存仓库配置")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: ThemeStyle.radiusSm)
                                    .fill(Color.primaryBlue)
                            )
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        resetToDefaults()
                    } label: {
                        Text("重置")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.textSecondary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: ThemeStyle.radiusSm)
                                    .fill(Color.bgSurfaceHover)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Text("修改后需要重新启动 App 或刷新 Essays 列表")
                .font(.system(size: 12))
                .foregroundColor(.textMuted)
        }
    }
    
    // MARK: - 图床配置
    
    private var imageConfigSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("图床配置")
            
            VStack(spacing: 12) {
                configInputRow(title: "图床仓库", placeholder: "图片存储仓库", text: $imageRepo)
                
                // CDN 类型选择
                HStack {
                    Text("CDN 类型")
                        .font(.system(size: 14))
                        .foregroundColor(.textSecondary)
                        .frame(width: 70, alignment: .leading)
                    
                    Picker("", selection: $cdnType) {
                        ForEach(cdnOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: ThemeStyle.radiusSm)
                        .fill(Color.bgSurface)
                )
                
                Button {
                    saveImageConfig()
                } label: {
                    Text("保存图床配置")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: ThemeStyle.radiusSm)
                                .fill(Color.primaryBlue)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - 缓存管理
    
    private var cacheSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("缓存")
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("本地缓存")
                        .font(.system(size: 15))
                        .foregroundColor(.textMain)
                    
                    Text(cacheSize)
                        .font(.system(size: 13))
                        .foregroundColor(.textMuted)
                }
                
                Spacer()
                
                Button {
                    showClearCacheAlert = true
                } label: {
                    Text("清除")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.errorRed)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: ThemeStyle.radiusSm)
                                .fill(Color.errorRed.opacity(0.15))
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: ThemeStyle.radiusMd)
                    .fill(Color.bgSurface)
            )
        }
    }
    
    // MARK: - 关于
    
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("关于")
            
            VStack(spacing: 0) {
                infoRow(title: "版本", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                
                Divider().background(Color.borderColor)
                
                infoRow(title: "构建", value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                
                Divider().background(Color.borderColor)
                
                // GitHub 链接
                Button {
                    if let url = URL(string: "https://github.com/ryusaksun/Swift_MarkdownEditor") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack {
                        Text("GitHub")
                            .font(.system(size: 15))
                            .foregroundColor(.textMain)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Text("开源仓库")
                                .font(.system(size: 14))
                                .foregroundColor(.primaryBlue)
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12))
                                .foregroundColor(.primaryBlue)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.plain)
            }
            .background(
                RoundedRectangle(cornerRadius: ThemeStyle.radiusMd)
                    .fill(Color.bgSurface)
            )
        }
    }
    
    // MARK: - 辅助视图
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.textSecondary)
            .textCase(.uppercase)
    }
    
    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 15))
                .foregroundColor(.textMain)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 15))
                .foregroundColor(.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
    
    private func configInputRow(title: String, placeholder: String, text: Binding<String>) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.textSecondary)
                .frame(width: 70, alignment: .leading)
            
            TextField(placeholder, text: text)
                .font(.system(size: 14))
                .foregroundColor(.textMain)
                .autocapitalization(.none)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: ThemeStyle.radiusSm)
                .fill(Color.bgSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: ThemeStyle.radiusSm)
                        .stroke(Color.borderColor, lineWidth: 1)
                )
        )
    }
    
    // MARK: - 数据操作
    
    private func loadSettings() {
        githubToken = KeychainHelper.get(key: "github_token") ?? ""
        githubOwner = AppConfig.githubOwner
        githubRepo = AppConfig.githubRepo
        githubBranch = AppConfig.githubBranch
        imageRepo = AppConfig.imageRepo
        cdnType = AppConfig.cdnType
    }
    
    private func saveToken() {
        HapticManager.impact(.light)
        if AppConfig.saveGitHubToken(githubToken) {
            verificationResult = .success("Token 已保存")
            HapticManager.notification(.success)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                if case .success("Token 已保存") = verificationResult {
                    verificationResult = nil
                }
            }
        } else {
            verificationResult = .failure("保存失败")
            HapticManager.notification(.error)
        }
    }
    
    private func saveAndVerifyToken() {
        guard !githubToken.isEmpty else { return }
        
        let saved = AppConfig.saveGitHubToken(githubToken)
        if !saved {
            verificationResult = .failure("保存失败")
            HapticManager.notification(.error)
            return
        }
        
        isVerifying = true
        verificationResult = nil
        HapticManager.impact(.light)
        
        Task {
            do {
                let username = try await GitHubService.shared.verifyToken(githubToken)
                await MainActor.run {
                    isVerifying = false
                    verificationResult = .success("已验证：\(username)")
                    HapticManager.notification(.success)
                }
            } catch {
                await MainActor.run {
                    isVerifying = false
                    verificationResult = .failure("Token 无效或已过期")
                    HapticManager.notification(.error)
                }
            }
        }
    }
    
    private func saveRepoConfig() {
        HapticManager.impact(.light)
        AppConfig.saveRepoConfig(
            owner: githubOwner.isEmpty ? "ryusaksun" : githubOwner,
            repo: githubRepo.isEmpty ? "astro_blog" : githubRepo,
            branch: githubBranch.isEmpty ? "main" : githubBranch
        )
        HapticManager.notification(.success)
    }
    
    private func saveImageConfig() {
        HapticManager.impact(.light)
        AppConfig.saveImageConfig(
            imageRepo: imageRepo.isEmpty ? "picx-images-hosting" : imageRepo,
            cdnType: cdnType
        )
        HapticManager.notification(.success)
    }
    
    private func resetToDefaults() {
        HapticManager.impact(.medium)
        AppConfig.resetToDefaults()
        // 重新加载默认值
        githubOwner = "ryusaksun"
        githubRepo = "astro_blog"
        githubBranch = "main"
        imageRepo = "picx-images-hosting"
        cdnType = "jsdelivr"
        HapticManager.notification(.success)
    }
    
    private func calculateCacheSize() {
        Task {
            let size = await getCacheSize()
            await MainActor.run {
                cacheSize = size
            }
        }
    }
    
    private func getCacheSize() async -> String {
        let fileManager = FileManager.default
        guard let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return "0 KB"
        }
        
        let essayCacheURL = cacheDir.appendingPathComponent("essays_cache.json")
        
        do {
            let attributes = try fileManager.attributesOfItem(atPath: essayCacheURL.path)
            if let size = attributes[.size] as? Int64 {
                if size < 1024 {
                    return "\(size) B"
                } else if size < 1024 * 1024 {
                    return String(format: "%.1f KB", Double(size) / 1024.0)
                } else {
                    return String(format: "%.1f MB", Double(size) / 1024.0 / 1024.0)
                }
            }
        } catch {
            return "0 KB"
        }
        
        return "0 KB"
    }
    
    private func clearCache() {
        Task {
            await EssayService.shared.clearCache()
            await MainActor.run {
                cacheSize = "0 KB"
                HapticManager.notification(.success)
            }
        }
    }
}

#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
}
