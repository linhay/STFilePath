//
//  DFAnyFile.swift
//  STFilePath
//
//  Created by linhey on 8/1/25.
//

import Foundation

public struct DFAnyFile<Model: Sendable>: Sendable, DownloadableFile {
    
    var _fetch: Fetch
    var _save: Save

    public func fetch() async throws -> Model {
        try await _fetch()
    }
    
    public func save(_ model: Model?) async throws {
        try await _save(model)
    }
    
}


public extension DFAnyFile {
    
    init(fetch: @escaping Fetch, save: @escaping Save) {
        self._fetch = fetch
        self._save = save
    }
    
    init(file: STFile) where Model == Data {
        self.init {
            try file.data()
        } save: { model in
            try file.overlay(with: model)
        }
    }
    
}
