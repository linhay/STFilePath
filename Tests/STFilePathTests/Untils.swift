//
//  File.swift
//  STFilePath
//
//  Created by linhey on 8/1/25.
//

import STFilePath
import Foundation

func createTestFolder() throws -> STFolder {
    #if os(Linux)
    // On Linux, use the temp directory directly since sandbox functionality is not available
    let tempDir = FileManager.default.temporaryDirectory
    return STFolder(tempDir).folder("testings/\(UUID().uuidString)")
    #else
    try STFolder(sanbox: .temporary).folder("testings/\(UUID().uuidString)")
    #endif
}
