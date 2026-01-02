//
//  MarkdownEditorView.swift
//  Swift_MarkdownEditor
//
//  Created by Ryuichi on 2025/12/26.
//

import SwiftUI

/// Markdown 编辑器视图
/// 支持实时图片预览
struct MarkdownEditorView: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool
    
    // 提取图片 URL
    private var imageUrls: [String] {
        extractImageUrls(from: text)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 图片预览区域（如果有图片）
            if !imageUrls.isEmpty {
                imagePreviewSection
            }
            
            // 文本编辑区域
            textEditorSection
        }
        .background(Color.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
    
    // MARK: - 图片预览区域
    
    private var imagePreviewSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(imageUrls, id: \.self) { url in
                    AsyncImage(url: URL(string: url)) { phase in
                        switch phase {
                        case .empty:
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.bgBody)
                                .frame(width: 120, height: 80)
                                .overlay(
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .primaryBlue))
                                )
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 120, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        case .failure:
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.bgBody)
                                .frame(width: 120, height: 80)
                                .overlay(
                                    Image(systemName: "exclamationmark.triangle")
                                        .foregroundColor(.errorRed)
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color.bgBody.opacity(0.5))
    }
    
    // MARK: - 文本编辑区域
    
    private var textEditorSection: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $text)
                .focused($isFocused)
                .font(.system(size: 16))
                .foregroundColor(.textMain)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
            
            // 占位符
            if text.isEmpty {
                Text("开始编写 Markdown...")
                    .font(.system(size: 16))
                    .foregroundColor(.textMuted)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                    .allowsHitTesting(false)
            }
        }
        .frame(maxHeight: .infinity)
        .onTapGesture {
            isFocused = true
        }
    }
    
    // MARK: - 提取图片 URL
    
    private func extractImageUrls(from text: String) -> [String] {
        let pattern = "!\\[.*?\\]\\((.*?)\\)"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return []
        }
        
        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, range: range)
        
        return matches.compactMap { match in
            guard let urlRange = Range(match.range(at: 1), in: text) else {
                return nil
            }
            return String(text[urlRange])
        }
    }
}

#Preview {
    MarkdownEditorView(text: .constant("# Hello\n\n![image](https://cdn.jsdelivr.net/gh/ryusaksun/picx-images-hosting@master/images/2025/12/img-test.jpg)"))
        .preferredColorScheme(.dark)
        .background(Color.bgBody)
        .padding()
        .frame(height: 400)
}
