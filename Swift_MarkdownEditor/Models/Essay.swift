//
//  Essay.swift
//  Swift_MarkdownEditor
//
//  Created by Ryuichi on 2025/12/31.
//

import Foundation

// MARK: - 静态正则表达式缓存（避免重复编译）

private enum EssayRegex {
    /// 匹配 Markdown 图片语法 ![alt](url)
    static let image = try! NSRegularExpression(pattern: #"!\[.*?\]\(.*?\)"#)
    
    /// 匹配 Markdown 链接语法 [text](url)
    static let link = try! NSRegularExpression(pattern: #"\[(.*?)\]\(.*?\)"#)
    
    /// 提取图片 URL
    static let imageURL = try! NSRegularExpression(pattern: #"!\[.*?\]\((.*?)\)"#)
}

// MARK: - 日期格式化器缓存（避免重复创建）

private enum EssayFormatter {
    /// 标准日期格式化器
    static let date: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()
    
    /// 相对时间格式化器
    static let relative: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.unitsStyle = .short
        return formatter
    }()
}

/// Essay 数据模型
/// 对应博客仓库中 src/content/essays/ 目录下的 Markdown 文件
struct Essay: Identifiable, Codable, Hashable {
    
    /// 使用文件名作为唯一标识
    var id: String { fileName }
    
    /// 完整文件名（如 "2025-12-27-124830.md"）
    let fileName: String
    
    /// 文件 SHA（用于 GitHub 更新操作）
    var sha: String?
    
    /// 标题（可选，从 frontmatter 或内容中提取）
    let title: String?
    
    /// 发布日期
    let pubDate: Date
    
    /// Markdown 正文内容（不含 frontmatter）
    let content: String
    
    /// 原始完整内容（含 frontmatter）
    let rawContent: String
    
    /// 内容预览（移除图片，只保留文字）
    var preview: String {
        var cleanContent = content
        
        // 使用缓存的正则移除 Markdown 图片语法 ![alt](url)
        cleanContent = EssayRegex.image.stringByReplacingMatches(
            in: cleanContent,
            range: NSRange(cleanContent.startIndex..., in: cleanContent),
            withTemplate: ""
        )
        
        // 使用缓存的正则移除链接语法 [text](url)，保留 text
        cleanContent = EssayRegex.link.stringByReplacingMatches(
            in: cleanContent,
            range: NSRange(cleanContent.startIndex..., in: cleanContent),
            withTemplate: "$1"
        )
        
        // 移除多余空白
        cleanContent = cleanContent
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if cleanContent.isEmpty {
            return "（图片）"
        }
        
        let maxLength = 100
        if cleanContent.count > maxLength {
            let index = cleanContent.index(cleanContent.startIndex, offsetBy: maxLength)
            return String(cleanContent[..<index]) + "..."
        }
        return cleanContent
    }
    
    /// 提取内容中的第一张图片 URL（用于预览）
    var firstImageURL: URL? {
        guard let match = EssayRegex.imageURL.firstMatch(in: content, range: NSRange(content.startIndex..., in: content)),
              let range = Range(match.range(at: 1), in: content) else {
            return nil
        }
        return URL(string: String(content[range]))
    }
    
    /// 是否包含图片
    var hasImage: Bool {
        return firstImageURL != nil
    }
    
    /// 格式化的日期字符串
    var formattedDate: String {
        EssayFormatter.date.string(from: pubDate)
    }
    
    /// 相对时间描述（如 "3天前"）
    var relativeDate: String {
        EssayFormatter.relative.localizedString(for: pubDate, relativeTo: Date())
    }
}

// MARK: - GitHub API 响应模型

/// GitHub Contents API 响应中的文件信息
struct GitHubFileInfo: Codable {
    let name: String
    let path: String
    let sha: String
    let size: Int
    let type: String
    let downloadUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case name, path, sha, size, type
        case downloadUrl = "download_url"
    }
}

// MARK: - Essay 解析器

nonisolated enum EssayParser {
    
    /// 从原始 Markdown 内容解析 Essay
    /// - Parameters:
    ///   - rawContent: 包含 frontmatter 的完整 Markdown 内容
    ///   - fileName: 文件名
    ///   - sha: 文件 SHA（可选，用于更新操作）
    /// - Returns: 解析后的 Essay 对象，解析失败返回 nil
    static func parse(rawContent: String, fileName: String, sha: String? = nil) -> Essay? {
        // 分离 frontmatter 和正文
        let (frontmatter, content) = separateFrontmatter(rawContent)
        
        // 解析发布日期
        guard let pubDate = parsePubDate(from: frontmatter, fileName: fileName) else {
            return nil
        }
        
        // 解析标题（可选）
        let title = parseTitle(from: frontmatter, content: content)
        
        return Essay(
            fileName: fileName,
            sha: sha,
            title: title,
            pubDate: pubDate,
            content: content,
            rawContent: rawContent
        )
    }
    
    /// 分离 frontmatter 和正文
    private static func separateFrontmatter(_ content: String) -> (frontmatter: String, body: String) {
        let pattern = #"^---\s*\n([\s\S]*?)\n---\s*\n?"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: content, range: NSRange(content.startIndex..., in: content)) else {
            return ("", content)
        }
        
        let frontmatterRange = Range(match.range(at: 1), in: content)!
        let fullMatchRange = Range(match.range, in: content)!
        
        let frontmatter = String(content[frontmatterRange])
        let body = String(content[fullMatchRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        
        return (frontmatter, body)
    }
    
    /// 从 frontmatter 或文件名解析发布日期
    private static func parsePubDate(from frontmatter: String, fileName: String) -> Date? {
        // 先尝试从 frontmatter 中提取 pubDate
        let datePattern = #"pubDate:\s*["\']?(\d{4}-\d{2}-\d{2}(?:\s+\d{2}:\d{2}(?::\d{2})?)?)["\']?"#
        
        if let regex = try? NSRegularExpression(pattern: datePattern),
           let match = regex.firstMatch(in: frontmatter, range: NSRange(frontmatter.startIndex..., in: frontmatter)),
           let range = Range(match.range(at: 1), in: frontmatter) {
            
            let dateString = String(frontmatter[range])
            
            // 尝试多种日期格式
            let formatters = [
                "yyyy-MM-dd HH:mm:ss",
                "yyyy-MM-dd HH:mm",
                "yyyy-MM-dd"
            ]
            
            for format in formatters {
                let formatter = DateFormatter()
                formatter.dateFormat = format
                formatter.locale = Locale(identifier: "en_US_POSIX")
                if let date = formatter.date(from: dateString) {
                    return date
                }
            }
        }
        
        // 回退：从文件名提取日期（格式：2025-12-27-HHMMSS.md 或 2025-12-27-标题-HHMMSS.md）
        let fileNamePattern = #"^(\d{4})-(\d{2})-(\d{2})(?:-.*?)?-?(\d{6})?"#
        
        if let regex = try? NSRegularExpression(pattern: fileNamePattern),
           let match = regex.firstMatch(in: fileName, range: NSRange(fileName.startIndex..., in: fileName)) {
            
            let year = Range(match.range(at: 1), in: fileName).map { String(fileName[$0]) } ?? "2025"
            let month = Range(match.range(at: 2), in: fileName).map { String(fileName[$0]) } ?? "01"
            let day = Range(match.range(at: 3), in: fileName).map { String(fileName[$0]) } ?? "01"
            
            var hour = "00", minute = "00", second = "00"
            if let timeRange = Range(match.range(at: 4), in: fileName) {
                let timeString = String(fileName[timeRange])
                if timeString.count == 6 {
                    hour = String(timeString.prefix(2))
                    minute = String(timeString.dropFirst(2).prefix(2))
                    second = String(timeString.suffix(2))
                }
            }
            
            let dateString = "\(year)-\(month)-\(day) \(hour):\(minute):\(second)"
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            return formatter.date(from: dateString)
        }
        
        return Date() // 无法解析时返回当前时间
    }
    
    /// 解析标题
    private static func parseTitle(from frontmatter: String, content: String) -> String? {
        // 先从 frontmatter 中查找 title
        let titlePattern = #"title:\s*["\']?(.+?)["\']?\s*$"#
        
        if let regex = try? NSRegularExpression(pattern: titlePattern, options: .anchorsMatchLines),
           let match = regex.firstMatch(in: frontmatter, range: NSRange(frontmatter.startIndex..., in: frontmatter)),
           let range = Range(match.range(at: 1), in: frontmatter) {
            let title = String(frontmatter[range]).trimmingCharacters(in: .whitespaces)
            if !title.isEmpty {
                return title
            }
        }
        
        // 回退：从内容中查找第一个 # 标题
        let headingPattern = #"^#\s+(.+)$"#
        if let regex = try? NSRegularExpression(pattern: headingPattern, options: .anchorsMatchLines),
           let match = regex.firstMatch(in: content, range: NSRange(content.startIndex..., in: content)),
           let range = Range(match.range(at: 1), in: content) {
            return String(content[range]).trimmingCharacters(in: .whitespaces)
        }
        
        return nil
    }
}
