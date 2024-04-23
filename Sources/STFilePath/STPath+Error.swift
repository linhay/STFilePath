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
public struct STPathError: LocalizedError {
    
    public static func noSuchFile(_ path: String) throws -> Error {
        throw STPathError(message: "no such file", code: 0)
    }
    
    public static func operationNotPermitted(_ path: String) throws -> Error {
        throw STPathError(message: "Operation not permitted", code: 1)
    }
    
    public let message: String
    public let code: Int
    public var errorDescription: String?
    
    public init(posix: Int32) {
        guard let code = POSIXErrorCode(rawValue: posix) else {
            self.init(message: "未知", code: -1)
            return
        }
        self.init(message: POSIXError(code).localizedDescription, code: Int(code.rawValue))
    }
    
    public init(message: String, code: Int = 0) {
        self.message = message
        self.errorDescription = message
        self.code = code
    }
}

