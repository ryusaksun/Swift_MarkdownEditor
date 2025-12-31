//
//  EssayRowView.swift
//  Swift_MarkdownEditor
//
//  Created by Ryuichi on 2025/12/31.
//

import SwiftUI

/// 图片缓存管理器
class ImageCache {
    static let shared = ImageCache()
    private var cache = NSCache<NSString, UIImage>()
    
    private init() {
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }
    
    func get(forKey key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }
    
    func set(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
}

/// 带缓存的网络图片视图
struct CachedAsyncImage: View {
    let url: URL?
    @State private var image: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .cornerRadius(8)
            } else if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .frame(height: 100)
            } else {
                EmptyView()
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        guard let url = url else {
            isLoading = false
            return
        }
        
        let cacheKey = url.absoluteString
        
        // 先检查缓存
        if let cachedImage = ImageCache.shared.get(forKey: cacheKey) {
            self.image = cachedImage
            self.isLoading = false
            return
        }
        
        // 从网络加载
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let uiImage = UIImage(data: data) {
                    // 存入缓存
                    ImageCache.shared.set(uiImage, forKey: cacheKey)
                    await MainActor.run {
                        self.image = uiImage
                        self.isLoading = false
                    }
                } else {
                    await MainActor.run {
                        self.isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}

/// Essay 时间轴行视图 - 完整展示模式
struct EssayRowView: View {
    let essay: Essay
    let isLast: Bool
    
    // 时间轴样式常量
    private let timelineColor = Color(hex: "#6B7280")
    private let dotSize: CGFloat = 8
    private let lineWidth: CGFloat = 2
    private let timelineWidth: CGFloat = 24
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // 左侧时间轴装饰
            timelineDecoration
            
            // 右侧内容区
            contentArea
        }
    }
    
    // MARK: - 时间轴装饰（连续垂直线）
    
    private var timelineDecoration: some View {
        ZStack(alignment: .top) {
            // 垂直连接线（贯穿整个区域）
            if !isLast {
                Rectangle()
                    .fill(timelineColor)
                    .frame(width: lineWidth)
            }
            
            // 节点圆点（在顶部）
            Circle()
                .fill(timelineColor)
                .frame(width: dotSize, height: dotSize)
                .padding(.top, 6)
        }
        .frame(width: timelineWidth)
    }
    
    // MARK: - 内容区
    
    private var contentArea: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 元数据行（作者 + 日期）
            metadataRow
            
            // 标题（如果有）
            if let title = essay.title, !title.isEmpty {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            // 完整正文内容
            if essay.preview != "（图片）" {
                Text(essay.preview)
                    .font(.body)
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // 完整尺寸图片（显示所有图片）
            ForEach(essay.allImageURLs, id: \.absoluteString) { imageURL in
                CachedAsyncImage(url: imageURL)
            }
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - 元数据行
    
    private var metadataRow: some View {
        HStack(spacing: 8) {
            Text("Ryuichi")
                .font(.caption)
                .foregroundColor(timelineColor)
            
            Text(essay.webFormattedDate)
                .font(.caption)
                .foregroundColor(timelineColor)
        }
    }
}

// MARK: - Essay 扩展

extension Essay {
    /// 网页风格的日期格式（2025/12/27 12:48）
    var webFormattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: pubDate)
    }
    
    /// 提取内容中的所有图片 URL
    var allImageURLs: [URL] {
        let pattern = #"!\[.*?\]\((.*?)\)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return []
        }
        
        let matches = regex.matches(in: content, range: NSRange(content.startIndex..., in: content))
        return matches.compactMap { match in
            guard let range = Range(match.range(at: 1), in: content) else { return nil }
            return URL(string: String(content[range]))
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 0) {
            EssayRowView(
                essay: Essay(
                    fileName: "test1.md",
                    title: nil,
                    pubDate: Date(),
                    content: "![image](https://cdn.jsdelivr.net/gh/SUNSIR007/picx-images-hosting@master/images/2025/12/img.jpg)",
                    rawContent: ""
                ),
                isLast: false
            )
            
            EssayRowView(
                essay: Essay(
                    fileName: "test2.md",
                    title: "这是一个标题",
                    pubDate: Date().addingTimeInterval(-86400),
                    content: "第二条随笔的内容，这里有很多文字。",
                    rawContent: ""
                ),
                isLast: true
            )
        }
        .padding()
    }
    .background(Color.black)
}
