import Foundation

/// [en] The type of change that occurred.
/// [zh] 发生的变化类型。
public enum STPathChangeKind: Sendable, Hashable {
    /// [en] The item was created.
    /// [zh] 项目被创建。
    case created
    /// [en] The item was deleted.
    /// [zh] 项目被删除。
    case deleted
    /// [en] The item was modified.
    /// [zh] 项目被修改。
    case modified
    /// [en] The item was renamed or moved.
    /// [zh] 项目被重命名或移动。
    case renamed
}

/// [en] Information about a file system change.
/// [zh] 关于文件系统变化的信息。
public struct STPathChanged: Sendable, Hashable {
    /// [en] The kind of change.
    /// [zh] 变化的类型。
    public let kind: STPathChangeKind
    /// [en] The path where the change occurred.
    /// [zh] 发生变化的路径。
    public let path: STPath

    public init(kind: STPathChangeKind, path: STPath) {
        self.kind = kind
        self.path = path
    }
}

/// [en] A protocol that defines a backend for file system monitoring.
/// [zh] 定义文件系统监听后端的协议。
protocol WatcherBackend: AnyObject, Sendable {
    /// [en] Starts monitoring and returns a stream of events.
    /// [zh] 开始监听并返回事件流。
    func start() -> AsyncThrowingStream<STPathChanged, Error>
    /// [en] Stops monitoring.
    /// [zh] 停止监听。
    func stop()
}
