//
//  TypedAnyFileMap.swift
//  Document
//
//  Created by linhey on 7/31/25.
//

import Foundation

/// [en] A protocol for files that can be fetched and saved asynchronously.
/// [zh] 一个用于可异步获取和保存的文件的协议。
public protocol DownloadableFile: Sendable {
    
    /// [en] The type of the model to be fetched and saved.
    /// [zh] 要获取和保存的模型的类型。
    associatedtype Model: Sendable
    /// [en] A closure that fetches the model data.
    /// [zh] 一个获取模型数据的闭包。
    typealias Fetch = @Sendable () async throws -> Model
    /// [en] A closure that saves the model data.
    /// [zh] 一个保存模型数据的闭包。
    typealias Save = @Sendable (_ model: Model?) async throws -> Void
    /// [en] A closure that transforms the fetched model data.
    /// [zh] 一个转换获取的模型数据的闭包。
    typealias FetchTransform<To: Sendable> = @Sendable (_  model: Model) async throws -> To
    /// [en] A closure that transforms the model data before saving.
    /// [zh] 一个在保存前转换模型数据的闭包。
    typealias SaveTransform<To: Sendable> = @Sendable (_ model: To) async throws -> Model
    
    /// [en] Fetches the model data.
    /// [zh] 获取模型数据。
    /// - Returns: The fetched model.
    /// - Throws: An error if the fetch operation fails.
    func fetch() async throws -> Model
    /// [en] Saves the model data.
    /// [zh] 保存模型数据。
    /// - Parameter model: The model to save.
    /// - Throws: An error if the save operation fails.
    func save(_ model: Model?) async throws

}

public extension DownloadableFile {
    
    /// [en] Maps the file to a new model type using fetch and save transformations.
    /// [zh] 使用 fetch 和 save 转换将文件映射到新的模型类型。
    /// - Parameters:
    ///   - fetch: A closure that transforms the fetched model data.
    ///   - save: A closure that transforms the model data before saving.
    /// - Returns: A `DFFileMap` instance for the new model type.
    func map<To: Sendable>(
        fetch: @escaping FetchTransform<To>,
        save: @escaping SaveTransform<To>
    ) -> DFFileMap<Self, To> {
        DFFileMap(file: self, fetch: fetch, save: save)
    }
    
#if canImport(Compression)
    /// [en] Compresses and decompresses the file data using the specified algorithm.
    /// [zh] 使用指定的算法压缩和解压缩文件数据。
    /// - Parameter algorithm: The compression algorithm to use.
    /// - Returns: A `DFFileMap` instance for the compressed data.
    func compression(_ algorithm: STComparator.Algorithm) -> DFFileMap<Self, Data> where Model == Data {
        self.map { model in
            try STComparator.decompress(model, algorithm: algorithm)
        } save: { model in
            try STComparator.compress(model, algorithm: algorithm)
        }
    }
#endif
    
    /// [en] Maps the file data to a `Codable` type.
    /// [zh] 将文件数据映射到 `Codable` 类型。
    /// - Parameters:
    ///   - kind: The `Codable` type to map to.
    ///   - encoder: The `JSONEncoder` to use for encoding.
    ///   - decoder: The `JSONDecoder` to use for decoding.
    /// - Returns: A `DFFileMap` instance for the `Codable` type.
    func codable<Kind: Codable>(
        _ kind: Kind.Type,
        encoder: JSONEncoder,
        decoder: JSONDecoder
    ) -> DFFileMap<Self, Kind> where Model == Data {
        self.map { model in
            try decoder.decode(kind.self, from: model)
        } save: { model in
            try encoder.encode(model)
        }
    }
    
    /// [en] Maps the file data to a `Codable` type with default encoder and decoder settings.
    /// [zh] 使用默认的编码器和解码器设置将文件数据映射到 `Codable` 类型。
    /// - Parameters:
    ///   - kind: The `Codable` type to map to.
    ///   - encoderOutputFormatting: The output formatting for the `JSONEncoder`.
    /// - Returns: A `DFFileMap` instance for the `Codable` type.
    func codable<Kind: Codable>(
        _ kind: Kind.Type,
        encoderOutputFormatting: JSONEncoder.OutputFormatting = [.prettyPrinted, .sortedKeys]
    ) -> DFFileMap<Self, Kind> where Model == Data {
        let encoder = JSONEncoder()
        encoder.dataEncodingStrategy = .base64
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = encoderOutputFormatting
        let decoder = JSONDecoder()
        decoder.dataDecodingStrategy = .base64
        decoder.dateDecodingStrategy = .iso8601
       return self.codable(kind, encoder: encoder, decoder: decoder)
    }
    
    /// [en] Erases the specific type of the file to `DFAnyFile`.
    /// [zh] 将文件的特定类型擦除为 `DFAnyFile`。
    /// - Returns: A `DFAnyFile` instance.
    /// - Throws: An error if the operation fails.
    func eraseToAnyFile() async throws -> DFAnyFile<Model> {
        .init {
            try await self.fetch()
        } save: { model in
            try await self.save(model)
        }
    }
    
}
