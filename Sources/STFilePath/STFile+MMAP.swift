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

#if canImport(Darwin)
import Darwin
import Foundation

// MARK: - Error
public extension STFile.System {
    
    class MMAP {
        
        let prot: MMAPProt
        let type: MMAPType
        let shareType: MMAPShareType
        let size: Int
        let offset: Int
        
        private(set) var fileSize: off_t
        
        let startPoint: UnsafeMutableRawPointer
        let descriptor: Int32
        
        init(descriptor: Int32,
             prot: MMAPProt,
             type: MMAPType,
             shareType: MMAPShareType,
             fileSize: off_t,
             size: Int,
             offset: Int = 0) throws {
            
            self.descriptor = descriptor
            self.prot = prot
            self.type = type
            self.shareType = shareType
            self.size = size
            self.offset = offset
            self.fileSize = fileSize
            self.startPoint = Darwin.mmap(nil,
                                          size,
                                          prot.rawValue,
                                          type.rawValue|shareType.rawValue,
                                          descriptor,
                                          .init(offset))
            if startPoint == MAP_FAILED {
                close(descriptor)
                throw STPathError(posix: Darwin.errno)
            }
        }
        
        deinit {
            ftruncate(descriptor, fileSize)
            fsync(descriptor)
            close(descriptor)
            munmap(startPoint, size)
        }
        
    }
    
}

public extension STFile.System.MMAP {
    
    func sync() {
        msync(startPoint, Int(fileSize), descriptor)
    }
    
    func read(range: Range<Int>? = nil) -> Data {
        if let range = range {
            return Data(bytes: startPoint + range.lowerBound, count: range.upperBound - range.lowerBound)
        }
        return Data(bytes: startPoint, count: .init(fileSize))
    }
    
    func append(data: Data) throws {
        try write(data: data, offset: Int(fileSize))
    }
    
    func write(data: Data, offset: Int = 0) throws {
        if data.count + offset > size {
            throw STPathError(message: "写入数据超出映射区大小, 映射区size: \(size)")
        }
        let point = startPoint + offset
        var data = data
        Darwin.memcpy(point, &data, data.count)
        fileSize = .init(offset + data.count)
    }
    
}
#endif
