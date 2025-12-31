//
//  EssaysListView.swift
//  Swift_MarkdownEditor
//
//  Created by Ryuichi on 2025/12/31.
//

import SwiftUI

/// Essays 列表视图 - 时间轴风格，完整展示模式
struct EssaysListView: View {
    @StateObject private var viewModel = EssayViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 纯黑背景
                Color.black
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    loadingView
                } else if let error = viewModel.errorMessage {
                    errorView(message: error)
                } else if viewModel.essays.isEmpty {
                    emptyView
                } else {
                    essaysTimeline
                }
            }
            .navigationTitle("Essays")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        .task {
            await viewModel.loadEssays()
        }
    }
    
    // MARK: - 时间轴列表（完整展示，无点击跳转）
    
    private var essaysTimeline: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(Array(viewModel.essays.enumerated()), id: \.element.id) { index, essay in
                    EssayRowView(
                        essay: essay,
                        isLast: index == viewModel.essays.count - 1
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
    
    // MARK: - 加载状态
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.2)
                .tint(.white)
            
            Text("加载中...")
                .font(.subheadline)
                .foregroundColor(Color(hex: "#6B7280"))
        }
    }
    
    // MARK: - 错误状态
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("加载失败")
                .font(.headline)
                .foregroundColor(.white)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(Color(hex: "#6B7280"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button {
                Task {
                    await viewModel.loadEssays(forceRefresh: true)
                }
            } label: {
                Label("重试", systemImage: "arrow.clockwise")
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color(hex: "#6B7280"))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
    }
    
    // MARK: - 空状态
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundColor(Color(hex: "#6B7280"))
            
            Text("暂无随笔")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("去写一些随笔吧")
                .font(.subheadline)
                .foregroundColor(Color(hex: "#6B7280"))
        }
    }
}

#Preview {
    EssaysListView()
}
