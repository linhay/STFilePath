//
//  DKFileMap.swift
//  STFilePath
//
//  Created by linhey on 8/1/25.
//

import Foundation

public struct DFFileMap<DKFile: DownloadableFile, To: Sendable>: Sendable, DownloadableFile {
    
    public typealias Model = To
    
    public let file: DKFile
    
    public let fetchTransform: DKFile.FetchTransform<To>
    public let saveTransform: DKFile.SaveTransform<To>
    
    public init(file: DKFile,
                fetch: @escaping DKFile.FetchTransform<To>,
                save: @escaping DKFile.SaveTransform<To>) {
        self.file = file
        self.fetchTransform = fetch
        self.saveTransform = save
    }
    
    public func fetch() async throws -> To {
        let data = try await file.fetch()
        return try await fetchTransform(data)
    }
    
    public func save(_ model: To?) async throws {
        if let model = model {
            let data = try await saveTransform(model)
            try await file.save(data)
        } else {
            try await file.save(nil)
        }
    }
    
}
