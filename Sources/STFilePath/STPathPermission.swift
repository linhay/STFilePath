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

public struct STPathPermission: OptionSet, Comparable {
    
    public static func < (lhs: STPathPermission, rhs: STPathPermission) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    // 不存在标记
    public static let none       = STPathPermission([])
    // 存在标记，表示所操作的文件路径是存在的
    public static let exists     = STPathPermission(rawValue: 1 << 0)
    // 可读标记，表示文件可读
    public static let readable   = STPathPermission(rawValue: 1 << 1)
    // 可写标记，表示文件可写
    public static let writable   = STPathPermission(rawValue: 1 << 2)
    // 可执行标记，表示文件可执行
    public static let executable = STPathPermission(rawValue: 1 << 3)
    // 可删除标记，表示文件可删除
    public static let deletable  = STPathPermission(rawValue: 1 << 4)

    
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public init(url: URL) {
        self.init(path: url.path)
    }
    
    public init(path: String) {
        let manager = FileManager.default
        var list = [STPathPermission]()
        
        guard manager.isExecutableFile(atPath: path) else {
            self.init(list)
            return
        }
        
        list.append(.exists)
        
        if manager.isReadableFile(atPath: path) {
            list.append(.readable)
        }
        
        if manager.isWritableFile(atPath: path) {
            list.append(.writable)
        }
        
        if manager.isDeletableFile(atPath: path) {
            list.append(.deletable)
        }
        
        if manager.isExecutableFile(atPath: path) {
            list.append(.executable)
        }
        
        self.init(list)
    }
    
}
