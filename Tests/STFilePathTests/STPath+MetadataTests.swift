import XCTest
@testable import STFilePath

class STPath_MetadataTests: XCTestCase {

    func testPermissions() throws {
        let folder = try createTestFolder()
        let file = try folder.create(file: "permission_test.txt")
        try file.set(permissions: STPathPermission.Posix([.ownerRead, .ownerWrite]))
        let permissions = try file.permissions()
        XCTAssertEqual(permissions, [.ownerRead, .ownerWrite])
        try file.delete()
    }

}
