//
//  DKFileMap.swift
//  STFilePath
//
//  Created by linhey on 8/1/25.
//

import Foundation

/// [en] A struct that maps a `DownloadableFile` to a new model type using transformations.
/// [zh] 一个使用转换将 `DownloadableFile` 映射到新模型类型的结构体。
public struct DFFileMap<DKFile: DownloadableFile, To: Sendable>: Sendable, DownloadableFile {
    
    public typealias Model = To
    
    /// [en] The underlying `DownloadableFile`.
    /// [zh] 底层的 `DownloadableFile`。
    public let file: DKFile
    
    /// [en] The transformation to apply when fetching the model.
    /// [zh] 获取模型时应用的转换。
    public let fetchTransform: DKFile.FetchTransform<To>
    /// [en] The transformation to apply when saving the model.
    /// [zh] 保存模型时应用的转换。
    public let saveTransform: DKFile.SaveTransform<To>
    
    /// [en] Initializes a new `DFFileMap` instance.
    /// [zh] 初始化一个新的 `DFFileMap` 实例。
    /// - Parameters:
    ///   - file: The underlying `DownloadableFile`.
    ///   - fetch: The transformation to apply when fetching the model.
    ///   - save: The transformation to apply when saving the model.
    public init(file: DKFile,
                fetch: @escaping DKFile.FetchTransform<To>,
                save: @escaping DKFile.SaveTransform<To>) {
        self.file = file
        self.fetchTransform = fetch
        self.saveTransform = save
    }
    
    /// [en] Fetches the model by applying the fetch transformation.
    /// [zh] 通过应用 fetch 转换来获取模型。
    /// - Returns: The transformed model.
    /// - Throws: An error if the fetch or transformation fails.
    public func fetch() async throws -> To {
        let data = try await file.fetch()
        return try await fetchTransform(data)
    }
    
    /// [en] Saves the model by applying the save transformation.
    /// [zh] 通过应用 save 转换来保存模型。
    /// - Parameter model: The model to save.
    /// - Throws: An error if the save or transformation fails.
    public func save(_ model: To?) async throws {
        if let model = model {
            let data = try await saveTransform(model)
            try await file.save(data)
        } else {
            try await file.save(nil)
        }
    }
    
}
