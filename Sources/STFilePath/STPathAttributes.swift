// MIT License
//
// Copyright (c) 2020 linhey
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation

public struct STPathNameComponents {
    
    public var name: String
    public var `extension`: String?
    public var filename: String { [name, self.extension].compactMap({ $0 }).joined(separator: ".") }
    public var isHidden: Bool { name.hasPrefix(".") }
    
    public init(_ name: String) {
        let lastPathComponent = name.split(separator: "/", omittingEmptySubsequences: true).last ?? ""
        let components = lastPathComponent.split(separator: ".", omittingEmptySubsequences: false)

        // 如果是隐藏文件且只有一个点，那么整个 lastPathComponent 是文件名
        if components.count == 1 {
            self.name = String(lastPathComponent)
            self.extension = nil
        } else {
            // 否则，除去第一个点的剩余部分是文件名，第二部分是扩展名
            self.name = (lastPathComponent.hasPrefix(".") ? "." : "") + components.dropLast().joined(separator: ".")
            self.extension = components.last?.description
        }
    }
}


// MARK: - Type
public class STPathAttributes {
    
    private let url: URL
    
    public init(path: URL) {
        self.url = path
    }
    
}

public extension STPathAttributes {
    
    /// 文件名
    var name: String { url.lastPathComponent.replacingOccurrences(of: ":", with: "/") }
    
    var nameComponents: STPathNameComponents { .init(name) }
   
    // isApplicationKey
    var attributes: [FileAttributeKey: Any] {
        (try? FileManager.default.attributesOfItem(atPath: url.path)) ?? [:]
    }
    
    /// 返回一个字符串数组，表示给定路径的用户可见组件。
    var componentsToDisplay: [String] {
        FileManager.default.componentsToDisplay(forPath: url.path) ?? []
    }
    
    /// 文件属性字典中的键，其值指示文件是否为只读。
    /// The key in a file attribute dictionary whose value indicates whether the file is read-only.
    var isReadOnly: Bool {
        get { get(.appendOnly, default: false) }
        set { set(.appendOnly, newValue) }
    }

    /// 文件属性字典中的键，其值指示文件是否繁忙。
    /// The key in a file attribute dictionary whose value indicates whether the file is busy.
    var isBusy: Bool {
        get { get(.busy, default: false) }
        set { set(.busy, newValue) }
    }

    /// 文件属性字典中的键，其值表示文件的创建日期。
    /// The key in a file attribute dictionary whose value indicates the file's creation date.
    var creationDate: Date {
        get { get(.creationDate, default: .distantPast) }
        set { set(.creationDate, newValue) }
    }

    /// 文件属性字典中的键，其值指示文件所在设备的标识符。
    /// The key in a file attribute dictionary whose value indicates the identifier for the device on which the file resides.
    var deviceIdentifier: Int {
        get { get(.deviceIdentifier, default: 0) }
        set { set(.deviceIdentifier, newValue) }
    }

    /// 文件属性字典中的键，其值指示文件的扩展名是否隐藏。
    /// The key in a file attribute dictionary whose value indicates whether the file’s extension is hidden.
    var extensionHidden: Bool {
        get { get(.extensionHidden, default: false) }
        set { set(.extensionHidden, newValue) }
    }

    /// 文件属性字典中的键，其值指示文件的组 ID。
    /// The key in a file attribute dictionary whose value indicates the file’s group ID.
    var groupOwnerAccountID: Int {
        get { get(.groupOwnerAccountID, default: 0) }
        set { set(.groupOwnerAccountID, newValue) }
    }

    /// 文件属性字典中的键，其值表示文件所有者的组名。
    /// The key in a file attribute dictionary whose value indicates the group name of the file’s owner.
    var groupOwnerAccountName: String {
        get { get(.groupOwnerAccountName, default: "") }
        set { set(.groupOwnerAccountName, newValue) }
    }

    /// 文件属性字典中的键，其值指示文件的 HFS 创建者代码。
    /// The key in a file attribute dictionary whose value indicates the file’s HFS creator code.
    var hfsCreatorCode: Int {
        get { get(.hfsCreatorCode, default: 0) }
        set { set(.hfsCreatorCode, newValue) }
    }

    /// 文件属性字典中的键，其值指示文件的 HFS 类型代码。
    /// The key in a file attribute dictionary whose value indicates the file’s HFS type code.
    var hfsTypeCode: Int {
        get { get(.hfsTypeCode, default: 0) }
        set { set(.hfsTypeCode, newValue) }
    }

    /// 文件属性字典中的键，其值指示文件是否可变。
    /// The key in a file attribute dictionary whose value indicates whether the file is mutable.
    var isImmutable: Bool {
        get { get(.immutable, default: true) }
        set { set(.immutable, newValue) }
    }

    /// 文件属性字典中的键，其值指示文件的上次修改日期。
    /// The key in a file attribute dictionary whose value indicates the file’s last modified date.
    var modificationDate: Date {
        get { get(.modificationDate, default: .distantPast) }
        set { set(.modificationDate, newValue) }
    }

    /// 文件属性字典中的键，其值表示文件所有者的帐户 ID。
    /// The key in a file attribute dictionary whose value indicates the file’s owner's account ID.
    var ownerAccountID: Int {
        get { get(.ownerAccountID, default: 0) }
        set { set(.ownerAccountID, newValue) }
    }

    /// 文件属性字典中的键，其值表示文件所有者的名称。
    /// The key in a file attribute dictionary whose value indicates the name of the file’s owner.
    var ownerAccountName: String {
       get { get(.ownerAccountName, default: "") }
       set { set(.ownerAccountName, newValue) }
   }
        
    /// 文件属性字典中的键，其值指示文件的 Posix 权限。
    /// The key in a file attribute dictionary whose value indicates the file’s Posix permissions.
    var posixPermissions: Int {
        get { get(.posixPermissions, default: 0) }
        set { set(.posixPermissions, newValue) }
    }
    
    #if !os(Linux)
    /// 文件属性字典中的键，其值标识此文件的保护级别。
    /// The key in a file attribute dictionary whose value identifies the protection level for this file.
    var protectionKey: Int {
        get { get(.protectionKey, default: 0) }
        set { set(.protectionKey, newValue) }
    }
    #endif
    
    
    /// 文件属性字典中的键，其值表示文件的引用计数。
    /// The key in a file attribute dictionary whose value indicates the file’s reference count.
    var referenceCount: Int {
        get { get(.referenceCount, default: 0) }
        set { set(.referenceCount, newValue) }
    }
    
    /// 文件属性字典中的键，其值指示文件的大小（以字节为单位）。
    /// The key in a file attribute dictionary whose value indicates the file’s size in bytes.
    var size: Int {
        get { get(.size, default: 0) }
        set { set(.size, newValue) }
    }
    
    /// 文件属性字典中的键，其值表示文件的文件系统文件号。
    /// The key in a file attribute dictionary whose value indicates the file’s filesystem file number.
    var systemFileNumber: Int {
        get { get(.systemFileNumber, default: 0) }
        set { set(.systemFileNumber, newValue) }
    }
    
    /// 文件系统属性字典中的键，其值表示文件系统中的空闲节点数。
    /// The key in a file system attribute dictionary whose value indicates the number of free nodes in the file system.
    var systemFreeNodes: Int {
        get { get(.systemFreeNodes, default: 0) }
        set { set(.systemFreeNodes, newValue) }
    }

    /// 文件系统属性字典中的键，其值指示文件系统上的可用空间量。
    /// The key in a file system attribute dictionary whose value indicates the amount of free space on the file system.
    var systemFreeSize: Int  {
        get { get(.systemFreeSize, default: 0) }
        set { set(.systemFreeSize, newValue) }
    }
       
    /// 文件系统属性字典中的键，其值表示文件系统中的节点数。
    /// The key in a file system attribute dictionary whose value indicates the number of nodes in the file system.
    var systemNodes: Int {
        get { get(.systemNodes, default: 0) }
        set { set(.systemNodes, newValue) }
    }
   
    /// 文件系统属性字典中的键，其值表示文件系统的文件系统编号。
    /// The key in a file system attribute dictionary whose value indicates the filesystem number of the file system.
    var systemNumber: Int {
        get { get(.systemNumber, default: 0) }
        set { set(.systemNumber, newValue) }
    }
    
    /// 文件系统属性字典中的键，其值指示文件系统的大小。
    /// The key in a file system attribute dictionary whose value indicates the size of the file system.
    var systemSize: Int {
        get { get(.systemSize, default: 0) }
        set { set(.systemSize, newValue) }
    }
        
    /// 文件属性字典中的键，其值指示文件的类型。
    /// The key in a file attribute dictionary whose value indicates the file’s type.
    var type: FileAttributeType {
        get { get(.type, default: .typeUnknown) }
        set { set(.type, newValue) }
    }

}

public extension STPathAttributes {
    
    func get<Value>(_ key: FileAttributeKey, default value: @autoclosure () -> Value) -> Value {
        get(key) ?? value()
    }
    
    func get<Value>(_ key: FileAttributeKey) -> Value? {
        do {
            let manager =  FileManager.default
            if !manager.isReadableFile(atPath: url.path) {
                return nil
            } else if let value = try manager.attributesOfItem(atPath: url.path)[key] as? Value {
                return value
            } else if let value = try manager.attributesOfFileSystem(forPath: url.path)[key] as? Value {
                return value
            } else {
                return nil
            }
        } catch {
            assertionFailure(error.localizedDescription)
            return nil
        }
        
    }
    
    func set<Value>(_ key: FileAttributeKey, _ newValue: Value) {
        do {
            try FileManager.default.setAttributes([key: newValue], ofItemAtPath: url.path)
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }
    
}
