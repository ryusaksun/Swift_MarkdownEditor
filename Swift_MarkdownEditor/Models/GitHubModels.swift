//
//  GitHubModels.swift
//  Swift_MarkdownEditor
//
//  Created by Ryuichi on 2025/12/31.
//

import Foundation

// MARK: - 响应模型

struct GHErrorResponse: Decodable, Sendable {
    let message: String
    
    enum CodingKeys: String, CodingKey {
        case message
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        message = try container.decode(String.self, forKey: .message)
    }
}

struct GHFileResponse: Decodable, Sendable {
    let name: String
    let path: String
    let sha: String
    let content: String
    let encoding: String
    
    enum CodingKeys: String, CodingKey {
        case name, path, sha, content, encoding
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        path = try container.decode(String.self, forKey: .path)
        sha = try container.decode(String.self, forKey: .sha)
        content = try container.decode(String.self, forKey: .content)
        encoding = try container.decode(String.self, forKey: .encoding)
    }
}

struct GHCreateFileResponse: Decodable, Sendable {
    let content: FileInfo
    
    struct FileInfo: Decodable, Sendable {
        let name: String
        let path: String
        let sha: String
        let htmlUrl: String
        
        enum CodingKeys: String, CodingKey {
            case name, path, sha
            case htmlUrl = "html_url"
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            name = try container.decode(String.self, forKey: .name)
            path = try container.decode(String.self, forKey: .path)
            sha = try container.decode(String.self, forKey: .sha)
            htmlUrl = try container.decode(String.self, forKey: .htmlUrl)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.content = try container.decode(FileInfo.self, forKey: .content)
    }
    
    enum CodingKeys: String, CodingKey {
        case content
    }
}

struct FileContent: Sendable {
    let content: String
    let sha: String
}

struct PublishResult: Sendable {
    let success: Bool
    let filePath: String
    let url: String
    let action: String
}

struct ImageUploadResult: Sendable {
    let success: Bool
    let path: String
    let url: String
    let sha: String
}
