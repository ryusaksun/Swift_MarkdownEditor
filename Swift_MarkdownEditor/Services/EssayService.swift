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
    
    /// 缓存的 Essays 列表
    private var cachedEssays: [Essay] = []
    
    /// 缓存时间戳
    private var cacheTimestamp: Date?
    
    /// 缓存有效期（5分钟）
    private let cacheValidity: TimeInterval = 5 * 60
    
    private init() {}
    
    // MARK: - Public API
    
    /// 获取所有 Essays 列表
    /// - Parameter forceRefresh: 是否强制刷新缓存
    /// - Returns: Essays 数组，按日期倒序排列
    func fetchEssays(forceRefresh: Bool = false) async throws -> [Essay] {
        // 检查缓存
        if !forceRefresh,
           let timestamp = cacheTimestamp,
           Date().timeIntervalSince(timestamp) < cacheValidity,
           !cachedEssays.isEmpty {
            return cachedEssays
        }
        
        do {
            // 获取文件列表
            let files = try await fetchFileList()
            
            // 只保留 .md 文件
            let mdFiles = files.filter { $0.name.hasSuffix(".md") }
            
            // 串行获取 Essay 内容（避免并发取消问题）
            var essays: [Essay] = []
            for file in mdFiles {
                // 检查是否被取消
                if Task.isCancelled {
                    // 如果被取消但有缓存，返回缓存
                    if !cachedEssays.isEmpty {
                        return cachedEssays
                    }
                    throw CancellationError()
                }
                
                if let essay = try? await fetchEssayContent(fileName: file.name) {
                    essays.append(essay)
                }
            }
            
            // 按日期倒序排列
            let sortedEssays = essays.sorted { $0.pubDate > $1.pubDate }
            
            // 更新缓存
            cachedEssays = sortedEssays
            cacheTimestamp = Date()
            
            return sortedEssays
        } catch is CancellationError {
            // 如果被取消但有缓存，返回缓存
            if !cachedEssays.isEmpty {
                return cachedEssays
            }
            throw EssayError.networkError("请求被取消")
        } catch {
            // 如果其他错误但有缓存，返回缓存
            if !cachedEssays.isEmpty && forceRefresh {
                return cachedEssays
            }
            throw error
        }
    }
    
    /// 获取单个 Essay 的完整内容
    /// - Parameter fileName: 文件名
    /// - Returns: Essay 对象
    func fetchEssayContent(fileName: String) async throws -> Essay {
        let urlString = "\(AppConfig.githubAPIBaseURL)/repos/\(AppConfig.githubOwner)/\(AppConfig.githubRepo)/contents/\(essaysPath)/\(fileName)?ref=\(AppConfig.githubBranch)"
        
        guard let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? urlString) else {
            throw EssayError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(AppConfig.githubToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.v3.raw", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw EssayError.networkError("无效的响应")
        }
        
        guard httpResponse.statusCode == 200 else {
            throw EssayError.networkError("HTTP \(httpResponse.statusCode)")
        }
        
        guard let content = String(data: data, encoding: .utf8) else {
            throw EssayError.parseError("无法解码内容")
        }
        
        guard let essay = EssayParser.parse(rawContent: content, fileName: fileName) else {
            throw EssayError.parseError("无法解析 Essay")
        }
        
        return essay
    }
    
    /// 清除缓存
    func clearCache() {
        cachedEssays = []
        cacheTimestamp = nil
    }
    
    // MARK: - Private Methods
    
    /// 获取 essays 目录下的文件列表
    private func fetchFileList() async throws -> [GitHubFileInfo] {
        let urlString = "\(AppConfig.githubAPIBaseURL)/repos/\(AppConfig.githubOwner)/\(AppConfig.githubRepo)/contents/\(essaysPath)?ref=\(AppConfig.githubBranch)"
        
        guard let url = URL(string: urlString) else {
            throw EssayError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(AppConfig.githubToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw EssayError.networkError("无效的响应")
        }
        
        guard httpResponse.statusCode == 200 else {
            throw EssayError.networkError("HTTP \(httpResponse.statusCode)")
        }
        
        let decoder = JSONDecoder()
        let files = try decoder.decode([GitHubFileInfo].self, from: data)
        
        return files
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
