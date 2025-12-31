//
//  EssayEditView.swift
//  Swift_MarkdownEditor
//
//  Created by Ryuichi on 2025/12/31.
//

import SwiftUI

/// Essay 编辑视图
struct EssayEditView: View {
    let essay: Essay
    @Environment(\.dismiss) private var dismiss
    
    @State private var content: String = ""
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccessToast = false
    
    var body: some View {
        ZStack {
            // 纯黑背景
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 编辑器
                VditorWebView(content: $content)
            }
            
            // 保存成功提示
            if showSuccessToast {
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("保存成功")
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.gray.opacity(0.8))
                    .cornerRadius(10)
                    .padding(.bottom, 50)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationTitle("编辑随笔")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: saveEssay) {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text("保存")
                            .fontWeight(.semibold)
                    }
                }
                .disabled(isSaving || content.isEmpty)
            }
        }
        .alert("保存失败", isPresented: $showError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            // 加载原始内容到编辑器
            content = essay.rawContent
        }
    }
    
    // MARK: - 保存 Essay
    
    private func saveEssay() {
        guard !isSaving else { return }
        
        isSaving = true
        
        Task {
            do {
                // 从 Vditor 获取最新内容
                let latestContent = await VditorManager.shared.getContent()
                let contentToSave = latestContent.isEmpty ? content : latestContent
                
                // 构建完整内容（保留原有 frontmatter，只更新正文）
                let finalContent = buildFinalContent(newBodyContent: contentToSave)
                
                // 调用服务更新
                let success = try await EssayService.shared.updateEssay(
                    essay: essay,
                    newContent: finalContent
                )
                
                await MainActor.run {
                    isSaving = false
                    
                    if success {
                        HapticManager.notification(.success)
                        showSuccessToast = true
                        
                        // 延迟返回
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            dismiss()
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                    showError = true
                    HapticManager.notification(.error)
                }
            }
        }
    }
    
    /// 构建完整内容（保留原有 frontmatter）
    private func buildFinalContent(newBodyContent: String) -> String {
        // 检查原始内容是否有 frontmatter
        let frontmatterPattern = #"^---\s*\n([\s\S]*?)\n---\s*\n?"#
        
        if let regex = try? NSRegularExpression(pattern: frontmatterPattern),
           let match = regex.firstMatch(in: essay.rawContent, range: NSRange(essay.rawContent.startIndex..., in: essay.rawContent)),
           let range = Range(match.range, in: essay.rawContent) {
            // 保留原有 frontmatter
            let frontmatter = String(essay.rawContent[range])
            return frontmatter + newBodyContent
        } else {
            // 没有 frontmatter，直接返回新内容
            return newBodyContent
        }
    }
}

#Preview {
    NavigationStack {
        EssayEditView(essay: Essay(
            fileName: "test.md",
            sha: nil,
            title: "测试随笔",
            pubDate: Date(),
            content: "这是测试内容",
            rawContent: "---\npubDate: 2025-12-31 12:00\n---\n\n这是测试内容"
        ))
    }
}
