//
//  TypedAnyFileMap.swift
//  Document
//
//  Created by linhey on 7/31/25.
//

import Foundation

public protocol DownloadableFile: Sendable {
    
    associatedtype Model: Sendable
    typealias Fetch = @Sendable () async throws -> Model
    typealias Save = @Sendable (_ model: Model?) async throws -> Void
    typealias FetchTransform<To: Sendable> = @Sendable (_  model: Model) async throws -> To
    typealias SaveTransform<To: Sendable> = @Sendable (_ model: To) async throws -> Model
    
    func fetch() async throws -> Model
    func save(_ model: Model?) async throws

}

public extension DownloadableFile {
    
    func map<To: Sendable>(
        fetch: @escaping FetchTransform<To>,
        save: @escaping SaveTransform<To>
    ) -> DFFileMap<Self, To> {
        DFFileMap(file: self, fetch: fetch, save: save)
    }
    
    func compression(_ algorithm: STComparator.Algorithm) -> DFFileMap<Self, Data> where Model == Data {
        self.map { model in
            try STComparator.decompress(model, algorithm: algorithm)
        } save: { model in
            try STComparator.compress(model, algorithm: algorithm)
        }
    }
    
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
    
    func eraseToAnyFile() async throws -> DFAnyFile<Model> {
        .init {
            try await self.fetch()
        } save: { model in
            try await self.save(model)
        }
    }
    
}
