//
//  EssayService.swift
//  Swift_MarkdownEditor
//
//  Created by Ryuichi on 2025/12/31.
//

import Foundation

/// Essay 服务 - 负责从 GitHub 获取 Essays 数据
actor EssayService {
    
    /// 单例
    static let shared = EssayService()
    
    /// Essays 目录路径
    private let essaysPath = "src/content/essays"
    
    /// 内存缓存的 Essays 列表
    private var cachedEssays: [Essay] = []
    
    /// 缓存时间戳
    private var cacheTimestamp: Date?
    
    /// 缓存有效期（5分钟）
    private let cacheValidity: TimeInterval = 5 * 60
    
    /// 正在加载
    private var isLoading = false
    
    /// 本地缓存文件路径
    private var localCacheURL: URL? {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("essays_cache.json")
    }
    
    private init() {
        // 启动时加载本地缓存
        loadLocalCache()
    }
    
    // MARK: - Public API
    
    /// 获取所有 Essays 列表
    /// - Parameter forceRefresh: 是否强制刷新缓存
    /// - Returns: Essays 数组，按日期倒序排列
    func fetchEssays(forceRefresh: Bool = false) async throws -> [Essay] {
        // 检查内存缓存（非强制刷新时）
        if !forceRefresh,
           let timestamp = cacheTimestamp,
           Date().timeIntervalSince(timestamp) < cacheValidity,
           !cachedEssays.isEmpty {
            print("📦 使用内存缓存，共 \(cachedEssays.count) 条")
            return cachedEssays
        }
        
        // 如果正在加载且有缓存，返回缓存
        if isLoading && !cachedEssays.isEmpty {
            print("⏳ 正在加载中，返回缓存")
            return cachedEssays
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // 获取文件列表
            let files = try await fetchFileList()
            
            // 只保留 .md 文件
            let mdFiles = files.filter { $0.name.hasSuffix(".md") }
            print("📄 发现 \(mdFiles.count) 个 Essay 文件")
            
            // 并发获取所有 Essay 内容
            let essays = await withTaskGroup(of: Essay?.self) { group in
                for file in mdFiles {
                    group.addTask {
                        try? await self.fetchEssayContent(fileName: file.name)
                    }
                }
                
                var results: [Essay] = []
                for await essay in group {
                    if let essay = essay {
                        results.append(essay)
                    }
                }
                return results
            }
            
            // 按日期倒序排列
            let sortedEssays = essays.sorted { $0.pubDate > $1.pubDate }
            
            // 更新内存缓存
            cachedEssays = sortedEssays
            cacheTimestamp = Date()
            
            // 保存到本地缓存
            saveLocalCache(sortedEssays)
            
            print("✅ 加载完成，共 \(sortedEssays.count) 条 Essay")
            return sortedEssays
            
        } catch {
            print("❌ 加载失败: \(error.localizedDescription)")
            
            // 如果网络失败但有缓存，返回缓存
            if !cachedEssays.isEmpty {
                print("📦 网络失败，使用缓存数据")
                return cachedEssays
            }
            
            throw error
        }
    }
    
    /// 获取缓存的 Essays（不发起网络请求）
    func getCachedEssays() -> [Essay] {
        return cachedEssays
    }
    
    /// 判断是否有缓存
    var hasCachedData: Bool {
        !cachedEssays.isEmpty
    }
    
    /// 判断缓存是否过期
    var isCacheExpired: Bool {
        guard let timestamp = cacheTimestamp else { return true }
        return Date().timeIntervalSince(timestamp) >= cacheValidity
    }
    
    /// 获取单个 Essay 的完整内容
    /// - Parameter fileName: 文件名
    /// - Returns: Essay 对象
    func fetchEssayContent(fileName: String) async throws -> Essay {
        let endpoint = "/repos/\(AppConfig.githubOwner)/\(AppConfig.githubRepo)/contents/\(essaysPath)/\(fileName)?ref=\(AppConfig.githubBranch)"
        
        do {
            let content = try await GitHubService.shared.fetchRawContent(endpoint: endpoint)
            
            guard let essay = EssayParser.parse(rawContent: content, fileName: fileName) else {
                throw EssayError.parseError("无法解析 Essay")
            }
            
            return essay
        } catch let error as GitHubError {
            switch error {
            case .notConfigured:
                throw EssayError.networkError("GitHub 未配置")
            case .apiError(let code, let message):
                throw EssayError.networkError("HTTP \(code): \(message)")
            default:
                throw EssayError.networkError(error.localizedDescription)
            }
        }
    }
    
    /// 清除缓存
    func clearCache() {
        cachedEssays = []
        cacheTimestamp = nil
        
        // 删除本地缓存文件
        if let url = localCacheURL {
            try? FileManager.default.removeItem(at: url)
        }
        print("🗑️ 缓存已清除")
    }
    
    // MARK: - Local Cache
    
    /// 本地缓存数据结构
    private struct LocalCache: Codable {
        let essays: [CachedEssay]
        let timestamp: Date
    }
    
    /// 可编码的 Essay 结构（用于本地缓存）
    private struct CachedEssay: Codable {
        let fileName: String
        let title: String?
        let pubDate: Date
        let content: String
        let rawContent: String
        
        init(from essay: Essay) {
            self.fileName = essay.fileName
            self.title = essay.title
            self.pubDate = essay.pubDate
            self.content = essay.content
            self.rawContent = essay.rawContent
        }
        
        func toEssay() -> Essay? {
            // 使用 EssayParser 重新解析，确保所有计算属性正确
            return EssayParser.parse(rawContent: rawContent, fileName: fileName)
        }
    }
    
    /// 加载本地缓存
    private func loadLocalCache() {
        guard let url = localCacheURL,
              FileManager.default.fileExists(atPath: url.path) else {
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let cache = try decoder.decode(LocalCache.self, from: data)
            
            // 检查本地缓存是否过期（24小时）
            let localCacheValidity: TimeInterval = 24 * 60 * 60
            if Date().timeIntervalSince(cache.timestamp) < localCacheValidity {
                cachedEssays = cache.essays.compactMap { $0.toEssay() }
                cacheTimestamp = cache.timestamp
                print("📂 从本地加载缓存，共 \(cachedEssays.count) 条")
            }
        } catch {
            print("⚠️ 加载本地缓存失败: \(error.localizedDescription)")
        }
    }
    
    /// 保存到本地缓存
    private func saveLocalCache(_ essays: [Essay]) {
        guard let url = localCacheURL else { return }
        
        do {
            let cachedEssays = essays.map { CachedEssay(from: $0) }
            let cache = LocalCache(essays: cachedEssays, timestamp: Date())
            
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(cache)
            
            try data.write(to: url)
            print("💾 缓存已保存到本地")
        } catch {
            print("⚠️ 保存本地缓存失败: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Private Methods
    
    /// 获取 essays 目录下的文件列表
    private func fetchFileList() async throws -> [GitHubFileInfo] {
        let endpoint = "/repos/\(AppConfig.githubOwner)/\(AppConfig.githubRepo)/contents/\(essaysPath)?ref=\(AppConfig.githubBranch)"
        
        do {
            let files: [GitHubFileInfo] = try await GitHubService.shared.request(endpoint: endpoint)
            return files
        } catch let error as GitHubError {
            switch error {
            case .notConfigured:
                throw EssayError.networkError("GitHub 未配置")
            case .apiError(let code, let message):
                throw EssayError.networkError("HTTP \(code): \(message)")
            default:
                throw EssayError.networkError(error.localizedDescription)
            }
        }
    }
}

// MARK: - Error Types

enum EssayError: LocalizedError {
    case invalidURL
    case networkError(String)
    case parseError(String)
    case notFound
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的 URL"
        case .networkError(let message):
            return "网络错误: \(message)"
        case .parseError(let message):
            return "解析错误: \(message)"
        case .notFound:
            return "未找到内容"
        }
    }
}

