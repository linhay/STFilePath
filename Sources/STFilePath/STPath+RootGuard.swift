import Foundation

#if canImport(Darwin)
import Darwin
#elseif os(Linux)
import Glibc
#endif

public extension STPathProtocol {

    /// [en] Returns whether the path is within the given root after canonicalization.
    /// [zh] 在规范化后，返回当前路径是否位于给定根路径内。
    func isWithin(root: any STPathProtocol) -> Bool {
        let target = canonicalPathForRootGuard(url: self.url)
        let rootPath = canonicalPathForRootGuard(url: root.url)
        if target == rootPath {
            return true
        }
        let rootPrefix = rootPath.hasSuffix("/") ? rootPath : rootPath + "/"
        return target.hasPrefix(rootPrefix)
    }

    /// [en] Asserts path is within root, otherwise throws.
    /// [zh] 断言路径位于根路径内，否则抛错。
    func assertWithin(root: any STPathProtocol) throws {
        guard isWithin(root: root) else {
            throw STPathError(
                message:
                    "[en] Path is outside allowed root. path=\(url.path), root=\(root.url.path) [zh] 路径超出允许根目录。path=\(url.path), root=\(root.url.path)")
        }
    }
}

private func canonicalPathForRootGuard(url: URL) -> String {
    let fileURL = url.isFileURL ? url : URL(fileURLWithPath: url.path)
    let standardized = fileURL.standardizedFileURL.path

    if let resolved = realpathString(standardized) {
        return resolved
    }

    var probingPath = standardized
    var suffixComponents = [String]()

    while !FileManager.default.fileExists(atPath: probingPath) {
        let ns = probingPath as NSString
        let last = ns.lastPathComponent
        if last.isEmpty || probingPath == "/" {
            break
        }
        suffixComponents.insert(last, at: 0)
        let parent = ns.deletingLastPathComponent
        if parent.isEmpty || parent == probingPath {
            break
        }
        probingPath = parent
    }

    if let resolvedAncestor = realpathString(probingPath) {
        var rebuilt = resolvedAncestor
        for component in suffixComponents {
            rebuilt = (rebuilt as NSString).appendingPathComponent(component)
        }
        return URL(fileURLWithPath: rebuilt).standardizedFileURL.path
    }

    return URL(fileURLWithPath: standardized).standardizedFileURL.path
}

private func realpathString(_ path: String) -> String? {
    var result: String?
    path.withCString { cPath in
        guard let resolved = realpath(cPath, nil) else { return }
        defer { free(resolved) }
        result = String(cString: resolved)
    }
    return result
}
