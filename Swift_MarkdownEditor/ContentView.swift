//
//  ContentView.swift
//  Swift_MarkdownEditor
//
//  Created by Ryuichi on 2025/12/26.
//

import SwiftUI
import PhotosUI

/// 主视图 - 匹配 PWA 布局
struct ContentView: View {
    @StateObject private var viewModel = EditorViewModel()
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    
    var body: some View {
        ZStack {
            // 深色背景 - 全屏统一颜色（响应主题变化）
            ThemeColors.current(themeManager.currentTheme).bgBody
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.3), value: themeManager.currentTheme)
            
            // 主内容
            VStack(spacing: 0) {
                // Header
                HeaderView(
                    viewModel: viewModel,
                    onImageUpload: {
                        HapticManager.impact(.light)
                        showImagePicker = true
                    },
                    onCameraCapture: {
                        HapticManager.impact(.light)
                        showCamera = true
                    }
                )
                
                // 分割线
                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 1)
                
                // Vditor 编辑器 - 保持圆角矩形风格
                VditorWebView(content: $viewModel.bodyContent)
                    .background(ThemeColors.current(themeManager.currentTheme).bgSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                themeManager.currentTheme == .oled
                                    ? Color.white.opacity(0.25)
                                    : Color.white.opacity(0.12),
                                lineWidth: 1
                            )
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                    .ignoresSafeArea(.keyboard)
                    .animation(.easeInOut(duration: 0.3), value: themeManager.currentTheme)
                    .onChange(of: themeManager.currentTheme) { _, newTheme in
                        // 立即同步 WebView 主题
                        VditorManager.shared.setTheme(newTheme)
                    }
            }
            
            // 上传 HUD（幽灵动画）
            if viewModel.showUploadHUD {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                
                GhostUploadHUDView(status: viewModel.uploadStatus)
            }
            
            // 发布反馈通过 Post 按钮显示（成功=对勾，失败=叉号）
        }
        .preferredColorScheme(.dark)
        .photosPicker(
            isPresented: $showImagePicker,
            selection: $selectedPhotoItems,
            maxSelectionCount: 9,
            matching: .images
        )
        .fullScreenCover(isPresented: $showCamera) {
            CameraView { capturedImage in
                Task {
                    await handleCapturedPhoto(capturedImage)
                }
            }
            .ignoresSafeArea()
        }
        .onChange(of: selectedPhotoItems) { _, newItems in
            Task {
                await handleSelectedPhotos(newItems)
            }
        }
        .onAppear {
            // 初始化时设置编辑器主题（等待 WebView 加载完成）
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                VditorManager.shared.setTheme(themeManager.currentTheme)
            }
        }
    }
    
    // MARK: - 多图片处理（聚合上传）
    
    private func handleSelectedPhotos(_ items: [PhotosPickerItem]) async {
        guard !items.isEmpty else { return }
        
        // 先加载所有图片
        var images: [UIImage] = []
        for item in items {
            do {
                if let data = try await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    images.append(image)
                }
            } catch {
                print("加载图片失败: \(error)")
            }
        }
        
        // 批量上传（显示一个聚合的上传窗口）
        let urls = await viewModel.uploadImages(images)
        
        // 依次插入图片
        for url in urls {
            VditorManager.shared.insertImage(url: url)
        }
        
        selectedPhotoItems = []
    }
    
    // MARK: - 拍照后处理
    
    private func handleCapturedPhoto(_ image: UIImage) async {
        // 上传照片
        let urls = await viewModel.uploadImages([image])
        
        // 插入图片到编辑器
        for url in urls {
            VditorManager.shared.insertImage(url: url)
        }
    }
}

#Preview {
    ContentView()
}
