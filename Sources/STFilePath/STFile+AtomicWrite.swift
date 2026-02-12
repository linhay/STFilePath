import Foundation

#if canImport(Darwin)
import Darwin
#elseif os(Linux)
import Glibc
#endif

public extension STFile {

    /// [en] Options for atomic file writes.
    /// [zh] 原子写入选项。
    struct AtomicWriteOptions: Sendable {
        /// [en] Whether to fsync the parent directory after replace.
        /// [zh] 在替换后是否 fsync 父目录。
        public var syncParentDirectory: Bool

        public init(syncParentDirectory: Bool = false) {
            self.syncParentDirectory = syncParentDirectory
        }
    }

    /// [en] Atomically writes data by using a temp file and rename.
    /// [zh] 通过临时文件和重命名执行原子写入。
    /// - Parameters:
    ///   - data: Data to write.
    ///   - options: Atomic write options.
    /// - Returns: The file itself.
    /// - Throws: An error when write/sync/replace fails.
    @discardableResult
    func atomicWrite(_ data: Data, options: AtomicWriteOptions = .init()) throws -> Self {
        let parent = STFolder(url.deletingLastPathComponent())
        try parent.create()

        let tempName = ".\(url.lastPathComponent).tmp.\(UUID().uuidString)"
        let tempFile = parent.file(tempName)

        do {
            try tempFile.create(with: data)
            try syncFile(at: tempFile.url.path)
            try replaceAtomically(tempPath: tempFile.url.path, targetPath: url.path)
            if options.syncParentDirectory {
                try syncDirectory(at: parent.url.path)
            }
        } catch {
            if tempFile.isExists {
                try? tempFile.delete()
            }
            throw error
        }

        return self
    }
}

#if canImport(Darwin) || os(Linux)
private func syncFile(at path: String) throws {
    let fd = open(path, O_RDONLY)
    if fd < 0 {
        throw STPathError(posix: errno)
    }
    defer { _ = close(fd) }
    if fsync(fd) != 0 {
        throw STPathError(posix: errno)
    }
}

private func replaceAtomically(tempPath: String, targetPath: String) throws {
    if rename(tempPath, targetPath) != 0 {
        throw STPathError(posix: errno)
    }
}

private func syncDirectory(at path: String) throws {
    let fd = open(path, O_RDONLY | O_DIRECTORY)
    if fd < 0 {
        throw STPathError(posix: errno)
    }
    defer { _ = close(fd) }
    if fsync(fd) != 0 {
        throw STPathError(posix: errno)
    }
}
#else
private func syncFile(at _: String) throws {
    throw STPathError(
        message:
            "[en] atomicWrite is unsupported on this platform. [zh] 当前平台不支持 atomicWrite。")
}

private func replaceAtomically(tempPath _: String, targetPath _: String) throws {
    throw STPathError(
        message:
            "[en] atomicWrite is unsupported on this platform. [zh] 当前平台不支持 atomicWrite。")
}

private func syncDirectory(at _: String) throws {
    throw STPathError(
        message:
            "[en] atomicWrite is unsupported on this platform. [zh] 当前平台不支持 atomicWrite。")
}
#endif
