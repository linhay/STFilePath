import Foundation

extension STFile {
    /// [en] Creates a watcher for the file.
    /// [zh] 为文件创建一个观察者。
    public func watcher() -> STFileWatcher {
        return STFileWatcher(file: self)
    }
}
