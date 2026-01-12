//
//  DFAnyFile.swift
//  STFilePath
//
//  Created by linhey on 8/1/25.
//

import Foundation

/// [en] A type-erased wrapper for any type that conforms to `DownloadableFile`.
/// [zh] 一个类型擦除的包装器，适用于任何符合 `DownloadableFile` 协议的类型。
public struct DFAnyFile<Model: Sendable>: Sendable, DownloadableFile {
    
    var _fetch: Fetch
    var _save: Save

    /// [en] Fetches the model data.
    /// [zh] 获取模型数据。
    /// - Returns: The fetched model.
    /// - Throws: An error if the fetch operation fails.
    public func fetch() async throws -> Model {
        try await _fetch()
    }
    
    /// [en] Saves the model data.
    /// [zh] 保存模型数据。
    /// - Parameter model: The model to save.
    /// - Throws: An error if the save operation fails.
    public func save(_ model: Model?) async throws {
        try await _save(model)
    }
    
}


public extension DFAnyFile {
    
    /// [en] Initializes a new `DFAnyFile` instance with fetch and save closures.
    /// [zh] 使用 fetch 和 save 闭包初始化一个新的 `DFAnyFile` 实例。
    /// - Parameters:
    ///   - fetch: A closure that fetches the model data.
    ///   - save: A closure that saves the model data.
    init(fetch: @escaping Fetch, save: @escaping Save) {
        self._fetch = fetch
        self._save = save
    }
    
    /// [en] Initializes a new `DFAnyFile` instance for raw data from a file.
    /// [zh] 为文件中的原始数据初始化一个新的 `DFAnyFile` 实例。
    /// - Parameter file: The file to read from and write to.
    init(file: STFile) where Model == Data {
        self.init {
            try file.data()
        } save: { model in
            try file.overlay(with: model)
        }
    }
    
}

public final class DFCurrentValueFile<File: DownloadableFile & Sendable>: @unchecked Sendable, DownloadableFile {
    public typealias Model = File.Model
    
    public let file: File
    public var value: File.Model? {
        set {
            _value = newValue
            save(newValue)
        }
        get { _value }
    }
    private var _value: File.Model?
    private var task: Task<(), any Error>?
    
    public init(file: File, initialValue value: File.Model? = nil) {
        self.file = file
        self._value = value
    }

    public func fetch() async throws -> Model {
        let value = try await file.fetch()
        self._value = value
        return value
    }
    
    public func save(_ model: Model?) async throws {
        try Task.checkCancellation()
        self._value = model
        try await file.save(model)
    }

    private func save(_ model: Model?) {
        task?.cancel()
        task = Task {
            do {
                try await save(model)
            } catch let error as CancellationError {
                debugPrint("Failed to save file: \(error)")
            } catch {
                debugPrint("Failed to save file: \(error)")
            }
        }
    }
    
}


public extension STFile {
    
    func toDFAnyFile() -> DFAnyFile<Data> {
        .init(file: self)
    }
    
}

