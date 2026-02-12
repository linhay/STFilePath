import Foundation
import STFilePath
import Testing

@Suite("STPath Root Guard Tests")
struct STPathRootGuardTests {

    @Test("Direct Child Is Within Root")
    func testDirectChildWithinRoot() throws {
        let root = try createTestFolder()
        defer { try? root.delete() }
        try root.create()

        let child = root.file("inside.txt")
        try child.create(with: Data("ok".utf8))

        #expect(child.isWithin(root: root))
        do {
            try child.assertWithin(root: root)
        } catch {
            #expect(Bool(false), "Expected child path to be allowed")
        }
    }

    @Test("Sibling Escape Is Not Within Root")
    func testSiblingEscapeDenied() throws {
        let root = try createTestFolder()
        defer { try? root.delete() }
        try root.create()

        let parent = try #require(root.parentFolder())
        let sibling = parent.file("outside_\(UUID().uuidString).txt")
        try sibling.create(with: Data("out".utf8))
        defer { try? sibling.delete() }

        #expect(!sibling.isWithin(root: root))
        #expect(throws: STPathError.self) {
            try sibling.assertWithin(root: root)
        }
    }

    @Test("Symlink Escape Is Not Within Root")
    func testSymlinkEscapeDenied() throws {
        let root = try createTestFolder()
        defer { try? root.delete() }
        try root.create()

        let parent = try #require(root.parentFolder())
        let outside = parent.file("outside_target_\(UUID().uuidString).txt")
        try outside.create(with: Data("outside".utf8))
        defer { try? outside.delete() }

        let link = root.subpath("link_to_outside")
        try link.createSymbolicLink(to: outside)

        #expect(!link.isWithin(root: root))
        #expect(throws: STPathError.self) {
            try link.assertWithin(root: root)
        }
    }

    @Test("Dot Components Input Is Canonicalized")
    func testDotComponentsInput() throws {
        let root = try createTestFolder()
        defer { try? root.delete() }
        try root.create()

        _ = try root.create(folder: "sub")
        _ = try root.create(file: "nested.txt", data: Data("v".utf8))

        let input = STPath("\(root.url.path)/sub/.././nested.txt")
        #expect(input.isWithin(root: root))
        do {
            try input.assertWithin(root: root)
        } catch {
            #expect(Bool(false), "Expected dot-components path inside root to be allowed")
        }
    }
}
