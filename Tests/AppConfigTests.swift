//
//  AppConfigTests.swift
//  Swift_MarkdownEditorTests
//
//  Created by Ryuichi on 2025/12/31.
//

import XCTest
@testable import Swift_MarkdownEditor

final class AppConfigTests: XCTestCase {

    func testGenerateImageCDNUrl() {
        let path = "test-image.jpg"
        let url = AppConfig.generateImageCDNUrl(path: path)
        
        // 基于当前默认配置 (jsdelivr)
        // githubOwner = "ryusaksun"
        // imageRepo = "picx-images-hosting"
        // imageBranch = "master"
        
        // 预期格式: "https://cdn.jsdelivr.net/gh/{owner}/{repo}@{branch}/{path}"
        let expectedUrl = "https://cdn.jsdelivr.net/gh/ryusaksun/picx-images-hosting@master/test-image.jpg"
        
        XCTAssertEqual(url, expectedUrl)
    }
    
    func testConstants() {
        // 验证基本常量不为空
        XCTAssertFalse(AppConfig.githubOwner.isEmpty)
        XCTAssertFalse(AppConfig.githubRepo.isEmpty)
        XCTAssertFalse(AppConfig.imageRepo.isEmpty)
        
        // 验证压缩质量在合理范围
        XCTAssertGreaterThan(AppConfig.imageQuality, 0)
        XCTAssertLessThanOrEqual(AppConfig.imageQuality, 1.0)
    }
}
