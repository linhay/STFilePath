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

#if !os(Linux)
    import Foundation

    extension STFolder {

        /// [en] A struct that represents a sandbox directory.
        /// [zh] 一个表示沙盒目录的结构体。
        public struct Sanbox {

            public let url: URL

            /// [en] The root directory of the sandbox.
            /// [zh] 沙盒的根目录。
            public static var root: Sanbox {
                .init(url: URL(fileURLWithPath: NSOpenStepRootDirectory()))
            }
            /// [en] The home directory of the sandbox.
            /// [zh] 沙盒的主目录。
            public static var home: Sanbox { .init(url: URL(fileURLWithPath: NSHomeDirectory())) }
            /// [en] The temporary directory of the sandbox.
            /// [zh] 沙盒的临时目录。
            public static var temporary: Sanbox {
                .init(url: URL(fileURLWithPath: NSTemporaryDirectory()))
            }

            /// [en] The documents directory of the sandbox.
            /// [zh] 沙盒的文档目录。
            public static var document: Sanbox {
                get throws {
                    .init(
                        url: try FileManager.default.url(
                            for: .documentDirectory, in: .userDomainMask, appropriateFor: nil,
                            create: false))
                }
            }
            /// [en] The library directory of the sandbox.
            /// [zh] 沙盒的库目录。
            public static var library: Sanbox {
                get throws {
                    .init(
                        url: try FileManager.default.url(
                            for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil,
                            create: false))
                }
            }
            /// [en] The caches directory of the sandbox.
            /// [zh] 沙盒的缓存目录。
            public static var cache: Sanbox {
                get throws {
                    .init(
                        url: try FileManager.default.url(
                            for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil,
                            create: false))
                }
            }
        }

        /// [en] Initializes a new `STFolder` instance from a sandbox directory.
        /// [zh] 从沙盒目录初始化一个新的 `STFolder` 实例。
        /// - Parameter rootPath: The sandbox directory.
        public init(sanbox rootPath: Sanbox) throws {
            self.init(rootPath.url)
        }

        /// [en] Initializes a new `STFolder` instance from an application group identifier.
        /// [zh] 从应用程序组标识符初始化一个新的 `STFolder` 实例。
        /// - Parameter applicationGroup: The application group identifier.
        /// - Throws: An error if the application group is not valid.
        public init(applicationGroup: String) throws {
            guard
                let url = FileManager.default.containerURL(
                    forSecurityApplicationGroupIdentifier: applicationGroup)
            else {
                throw STPathError(
                    message:
                        "[en] Application group cannot be identified [zh] applicationGroup 无法识别")
            }
            self.init(url)
        }

        /// [en] Initializes a new `STFolder` instance from a ubiquity container identifier.
        /// [zh] 从 ubiquity 容器标识符初始化一个新的 `STFolder` 实例。
        /// - Parameter ubiquityContainerIdentifier: The ubiquity container identifier.
        /// - Throws: An error if iCloud is not available.
        public init(ubiquityContainerIdentifier: String) throws {
            guard
                let url = FileManager.default.url(
                    forUbiquityContainerIdentifier: ubiquityContainerIdentifier)
            else {
                throw STPathError(message: "[en] iCloud is not available [zh] iCloud 不可用")
            }
            self.init(url)
        }

        /// [en] Initializes a new `STFolder` instance from an iCloud container identifier.
        /// [zh] 从 iCloud 容器标识符初始化一个新的 `STFolder` 实例。
        /// - Parameter identifier: The iCloud container identifier.
        /// - Throws: An error if iCloud is not available.
        public init(iCloud identifier: String) throws {
            try self.init(ubiquityContainerIdentifier: identifier)
        }

    }
#endif
