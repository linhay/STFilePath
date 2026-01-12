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

/// [en] A struct that represents the components of a path name.
/// [zh] 一个表示路径名称组件的结构体。
public struct STPathNameComponents {
    
    /// [en] The name of the file or folder.
    /// [zh] 文件或文件夹的名称。
    public var name: String
    /// [en] The extension of the file.
    /// [zh] 文件的扩展名。
    public var `extension`: String?
    /// [en] The full file name, including the extension.
    /// [zh] 完整的文件名，包括扩展名。
    public var filename: String { [name, self.extension].compactMap({ $0 }).joined(separator: ".") }
    /// [en] Whether the file or folder is hidden.
    /// [zh] 文件或文件夹是否是隐藏的。
    public var isHidden: Bool { name.hasPrefix(".") }
    
    public init(_ name: String) {
        let path = name
        let pathComponents = path.split(separator: "/", omittingEmptySubsequences: true)
        let lastPathComponent = pathComponents.last.map(String.init) ?? ""
        if lastPathComponent.isEmpty {
            self.name = ""
            self.extension = nil
        } else if lastPathComponent.hasPrefix(".") {
            // Hidden file, check for multiple dots
            let dotComponents = lastPathComponent.dropFirst().split(separator: ".", omittingEmptySubsequences: false)
            if dotComponents.count <= 1 {
                self.name = lastPathComponent
                self.extension = nil
            } else {
                let ext = dotComponents.last.map(String.init)
                let namePart = "." + dotComponents.dropLast().joined(separator: ".")
                self.name = namePart
                self.extension = ext
            }
        } else {
            let dotComponents = lastPathComponent.split(separator: ".", omittingEmptySubsequences: false)
            if dotComponents.count == 1 {
                self.name = lastPathComponent
                self.extension = nil
            } else {
                self.name = dotComponents.dropLast().joined(separator: ".")
                self.extension = dotComponents.last.map(String.init)
            }
        }
    }
}


// MARK: - Type
/// [en] A class that provides access to the attributes of a path.
/// [zh] 一个提供对路径属性访问的类。
public class STPathAttributes {
    
    private let url: URL
    
    public init(path: URL) {
        self.url = path
    }
    
}

public extension STPathAttributes {
    
    /// [en] The name of the file or folder.
    /// [zh] 文件或文件夹的名称。
    var name: String { url.lastPathComponent.replacingOccurrences(of: ":", with: "/") }
    
    /// [en] The components of the path name.
    /// [zh] 路径名称的组件。
    var nameComponents: STPathNameComponents { .init(name) }
   
    /// [en] The attributes of the item.
    /// [zh] 项目的属性。
    var attributes: [FileAttributeKey: Any] {
        (try? FileManager.default.attributesOfItem(atPath: url.path)) ?? [:]
    }
    
    /// [en] An array of strings representing the user-visible components of the path.
    /// [zh] 一个字符串数组，表示路径的用户可见组件。
    var componentsToDisplay: [String] {
        FileManager.default.componentsToDisplay(forPath: url.path) ?? []
    }
    
    /// [en] The key in a file attribute dictionary whose value indicates whether the file is read-only.
    /// [zh] 文件属性字典中的键，其值指示文件是否为只读。
    var isReadOnly: Bool {
        get { get(.appendOnly, default: false) }
        set { set(.appendOnly, newValue) }
    }

    /// [en] The key in a file attribute dictionary whose value indicates whether the file is busy.
    /// [zh] 文件属性字典中的键，其值指示文件是否繁忙。
    var isBusy: Bool {
        get { get(.busy, default: false) }
        set { set(.busy, newValue) }
    }

    /// [en] The key in a file attribute dictionary whose value indicates the file's creation date.
    /// [zh] 文件属性字典中的键，其值表示文件的创建日期。
    var creationDate: Date {
        get { get(.creationDate, default: .distantPast) }
        set { set(.creationDate, newValue) }
    }

    /// [en] The key in a file attribute dictionary whose value indicates the identifier for the device on which the file resides.
    /// [zh] 文件属性字典中的键，其值指示文件所在设备的标识符。
    var deviceIdentifier: Int {
        get { get(.deviceIdentifier, default: 0) }
        set { set(.deviceIdentifier, newValue) }
    }

    /// [en] The key in a file attribute dictionary whose value indicates whether the file’s extension is hidden.
    /// [zh] 文件属性字典中的键，其值指示文件的扩展名是否隐藏。
    var extensionHidden: Bool {
        get { get(.extensionHidden, default: false) }
        set { set(.extensionHidden, newValue) }
    }

    /// [en] The key in a file attribute dictionary whose value indicates the file’s group ID.
    /// [zh] 文件属性字典中的键，其值指示文件的组 ID。
    var groupOwnerAccountID: Int {
        get { get(.groupOwnerAccountID, default: 0) }
        set { set(.groupOwnerAccountID, newValue) }
    }

    /// [en] The key in a file attribute dictionary whose value indicates the group name of the file’s owner.
    /// [zh] 文件属性字典中的键，其值表示文件所有者的组名。
    var groupOwnerAccountName: String {
        get { get(.groupOwnerAccountName, default: "") }
        set { set(.groupOwnerAccountName, newValue) }
    }

    /// [en] The key in a file attribute dictionary whose value indicates the file’s HFS creator code.
    /// [zh] 文件属性字典中的键，其值指示文件的 HFS 创建者代码。
    var hfsCreatorCode: Int {
        get { get(.hfsCreatorCode, default: 0) }
        set { set(.hfsCreatorCode, newValue) }
    }

    /// [en] The key in a file attribute dictionary whose value indicates the file’s HFS type code.
    /// [zh] 文件属性字典中的键，其值指示文件的 HFS 类型代码。
    var hfsTypeCode: Int {
        get { get(.hfsTypeCode, default: 0) }
        set { set(.hfsTypeCode, newValue) }
    }

    /// [en] The key in a file attribute dictionary whose value indicates whether the file is mutable.
    /// [zh] 文件属性字典中的键，其值指示文件是否可变。
    var isImmutable: Bool {
        get { get(.immutable, default: true) }
        set { set(.immutable, newValue) }
    }

    /// [en] The key in a file attribute dictionary whose value indicates the file’s last modified date.
    /// [zh] 文件属性字典中的键，其值指示文件的上次修改日期。
    var modificationDate: Date {
        get { get(.modificationDate, default: .distantPast) }
        set { set(.modificationDate, newValue) }
    }

    /// [en] The key in a file attribute dictionary whose value indicates the file’s owner's account ID.
    /// [zh] 文件属性字典中的键，其值表示文件所有者的帐户 ID。
    var ownerAccountID: Int {
        get { get(.ownerAccountID, default: 0) }
        set { set(.ownerAccountID, newValue) }
    }

    /// [en] The key in a file attribute dictionary whose value indicates the name of the file’s owner.
    /// [zh] 文件属性字典中的键，其值表示文件所有者的名称。
    var ownerAccountName: String {
       get { get(.ownerAccountName, default: "") }
       set { set(.ownerAccountName, newValue) }
   }
        
    /// [en] The key in a file attribute dictionary whose value indicates the file’s Posix permissions.
    /// [zh] 文件属性字典中的键，其值指示文件的 Posix 权限。
    var posixPermissions: Int {
        get { get(.posixPermissions, default: 0) }
        set { set(.posixPermissions, newValue) }
    }
    
    #if !os(Linux)
    /// [en] The key in a file attribute dictionary whose value identifies the protection level for this file.
    /// [zh] 文件属性字典中的键，其值标识此文件的保护级别。
    var protectionKey: Int {
        get { get(.protectionKey, default: 0) }
        set { set(.protectionKey, newValue) }
    }
    #endif
    
    
    /// [en] The key in a file attribute dictionary whose value indicates the file’s reference count.
    /// [zh] 文件属性字典中的键，其值表示文件的引用计数。
    var referenceCount: Int {
        get { get(.referenceCount, default: 0) }
        set { set(.referenceCount, newValue) }
    }
    
    /// [en] The key in a file attribute dictionary whose value indicates the file’s size in bytes.
    /// [zh] 文件属性字典中的键，其值指示文件的大小（以字节为单位）。
    var size: Int {
        get { get(.size, default: 0) }
        set { set(.size, newValue) }
    }
    
    /// [en] The key in a file attribute dictionary whose value indicates the file’s filesystem file number.
    /// [zh] 文件属性字典中的键，其值表示文件的文件系统文件号。
    var systemFileNumber: Int {
        get { get(.systemFileNumber, default: 0) }
        set { set(.systemFileNumber, newValue) }
    }
    
    /// [en] The key in a file system attribute dictionary whose value indicates the number of free nodes in the file system.
    /// [zh] 文件系统属性字典中的键，其值表示文件系统中的空闲节点数。
    var systemFreeNodes: Int {
        get { get(.systemFreeNodes, default: 0) }
        set { set(.systemFreeNodes, newValue) }
    }

    /// [en] The key in a file system attribute dictionary whose value indicates the amount of free space on the file system.
    /// [zh] 文件系统属性字典中的键，其值指示文件系统上的可用空间量。
    var systemFreeSize: Int  {
        get { get(.systemFreeSize, default: 0) }
        set { set(.systemFreeSize, newValue) }
    }
       
    /// [en] The key in a file system attribute dictionary whose value indicates the number of nodes in the file system.
    /// [zh] 文件系统属性字典中的键，其值表示文件系统中的节点数。
    var systemNodes: Int {
        get { get(.systemNodes, default: 0) }
        set { set(.systemNodes, newValue) }
    }
   
    /// [en] The key in a file system attribute dictionary whose value indicates the filesystem number of the file system.
    /// [zh] 文件系统属性字典中的键，其值表示文件系统的文件系统编号。
    var systemNumber: Int {
        get { get(.systemNumber, default: 0) }
        set { set(.systemNumber, newValue) }
    }
    
    /// [en] The key in a file system attribute dictionary whose value indicates the size of the file system.
    /// [zh] 文件系统属性字典中的键，其值指示文件系统的大小。
    var systemSize: Int {
        get { get(.systemSize, default: 0) }
        set { set(.systemSize, newValue) }
    }
        
    /// [en] The key in a file attribute dictionary whose value indicates the file’s type.
    /// [zh] 文件属性字典中的键，其值指示文件的类型。
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
