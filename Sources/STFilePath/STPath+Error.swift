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

// MARK: - Error
/// [en] An error that can occur when working with file paths.
/// [zh] 处理文件路径时可能发生的错误。
public struct STPathError: LocalizedError {
    
    /// [en] Creates an error indicating that there is no such file.
    /// [zh] 创建一个指示没有此类文件的错误。
    /// - Parameter path: The path of the file.
    /// - Returns: An error.
    /// - Throws: The error.
    public static func noSuchFile(_ path: String) throws -> Error {
        throw STPathError(message: "[en] no such file 
 [zh] 没有这样的文件", code: 0)
    }
    
    /// [en] Creates an error indicating that the operation is not permitted.
    /// [zh] 创建一个指示操作不允许的错误。
    /// - Parameter path: The path of the file.
    /// - Returns: An error.
    /// - Throws: The error.
    public static func operationNotPermitted(_ path: String) throws -> Error {
        throw STPathError(message: "[en] Operation not permitted 
 [zh] 操作不允许", code: 1)
    }
    
    /// [en] The error message.
    /// [zh] 错误消息。
    public let message: String
    /// [en] The error code.
    /// [zh] 错误代码。
    public let code: Int
    public var errorDescription: String?
    
    /// [en] Initializes a new `STPathError` instance from a POSIX error code.
    /// [zh] 从 POSIX 错误代码初始化一个新的 `STPathError` 实例。
    /// - Parameter posix: The POSIX error code.
    public init(posix: Int32) {
        guard let code = POSIXErrorCode(rawValue: posix) {
            self.init(message: "[en] Unknown 
 [zh] 未知", code: -1)
            return
        }
        self.init(message: POSIXError(code).localizedDescription, code: Int(code.rawValue))
    }
    
    /// [en] Initializes a new `STPathError` instance.
    /// [zh] 初始化一个新的 `STPathError` 实例。
    /// - Parameters:
    ///   - message: The error message.
    ///   - code: The error code.
    public init(message: String, code: Int = 0) {
        self.message = message
        self.errorDescription = message
        self.code = code
    }
}

