import Testing
import STFilePath
import Foundation

@Suite("DownloadableFile Tests")
struct DownloadableFileTests {

    struct MyModel: Codable, Equatable, Sendable {
        let name: String
        let value: Int
    }

    @Test("Codable Transformation")
    func testCodable() async throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }
        
        let file = testFolder.file("model.json")
        let downloadableFile = DFAnyFile(file: file).codable(MyModel.self)

        // 1. Save a model
        let model1 = MyModel(name: "first", value: 1)
        try await downloadableFile.save(model1)
        #expect(file.isExist)

        // 2. Fetch the model and verify
        let fetchedModel1 = try await downloadableFile.fetch()
        #expect(fetchedModel1 == model1)

        // 3. Save a new model
        let model2 = MyModel(name: "second", value: 2)
        try await downloadableFile.save(model2)
        let fetchedModel2 = try await downloadableFile.fetch()
        #expect(fetchedModel2 == model2)
        #expect(fetchedModel2 != model1)
    }

    @Test("Compression Transformation")
    func testCompression() async throws {
        let testFolder = try createTestFolder()
        defer { try? testFolder.delete() }

        let file = testFolder.file("compressed.dat")
        let downloadableFile = DFAnyFile(file: file).compression(.zlib)

        let originalData = "this is a long string that should compress well".data(using: .utf8)!

        // 1. Save compressed data
        try await downloadableFile.save(originalData)
        #expect(file.isExist)
        
        let compressedData = try file.data()
        #expect(compressedData.count < originalData.count)

        // 2. Fetch and decompress data
        let decompressedData = try await downloadableFile.fetch()
        #expect(decompressedData == originalData)
    }
}
