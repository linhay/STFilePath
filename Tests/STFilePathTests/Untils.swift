//
//  File.swift
//  STFilePath
//
//  Created by linhey on 8/1/25.
//

import STFilePath
import Foundation

func createTestFolder() throws -> STFolder {
    try STFolder(sanbox: .temporary).folder("testings/\(UUID().uuidString)")
}
