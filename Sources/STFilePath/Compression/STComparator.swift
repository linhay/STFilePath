import Foundation
import Compression

/// [en] A struct that provides compression and decompression functionality.
/// [zh] 一个提供压缩和解压缩功能的结构体。
public struct STComparator {
    
    /// [en] The compression algorithm to use.
    /// [zh] 要使用的压缩算法。
    public enum Algorithm: Sendable {
        case lz4
        case zlib
        case lzma
        case lzfse

        var rawValue: compression_algorithm {
            switch self {
            case .lz4: return COMPRESSION_LZ4
            case .zlib: return COMPRESSION_ZLIB
            case .lzma: return COMPRESSION_LZMA
            case .lzfse: return COMPRESSION_LZFSE
            }
        }
    }

    /// [en] Errors that can occur during compression or decompression.
    /// [zh] 压缩或解压缩过程中可能发生的错误。
    public enum Errors: Error {
        /// [en] Compression failed.
        /// [zh] 压缩失败。
        case compressionFailed
        /// [en] Decompression failed.
        /// [zh] 解压缩失败。
        case decompressionFailed
    }

    
    /// [en] Compresses the given data using the specified algorithm.
    /// [zh] 使用指定的算法压缩给定的数据。
    /// - Parameters:
    ///   - data: The data to compress.
    ///   - algorithm: The compression algorithm to use.
    /// - Returns: The compressed data.
    /// - Throws: An error if compression fails.
    public static func compress(_ data: Data, algorithm: Algorithm) throws -> Data {
        return try perform(data: data, operation: COMPRESSION_STREAM_ENCODE, algorithm: algorithm)
    }

    /// [en] Decompresses the given data using the specified algorithm.
    /// [zh] 使用指定的算法解压缩给定的数据。
    /// - Parameters:
    ///   - data: The data to decompress.
    ///   - algorithm: The compression algorithm to use.
    /// - Returns: The decompressed data.
    /// - Throws: An error if decompression fails.
    public static func decompress(_ data: Data, algorithm: Algorithm) throws -> Data {
        return try perform(data: data, operation: COMPRESSION_STREAM_DECODE, algorithm: algorithm)
    }

}

private extension STComparator {
    
    static func perform(data: Data, operation: compression_stream_operation, algorithm: Algorithm) throws -> Data {
        let streamPointer = UnsafeMutablePointer<compression_stream>.allocate(capacity: 1)
        defer { streamPointer.deallocate() }

        var stream = streamPointer.pointee
        var status = compression_stream_init(&stream, operation, algorithm.rawValue)
        guard status != COMPRESSION_STATUS_ERROR else {
            throw operation == COMPRESSION_STREAM_ENCODE ? Errors.compressionFailed : Errors.decompressionFailed
        }
        defer { compression_stream_destroy(&stream) }

        return try data.withUnsafeBytes { (srcBuffer: UnsafeRawBufferPointer) in
            guard let srcPointer = srcBuffer.bindMemory(to: UInt8.self).baseAddress else {
                throw operation == COMPRESSION_STREAM_ENCODE ? Errors.compressionFailed : Errors.decompressionFailed
            }

            let dstBufferSize = 64 * 1024
            let dstBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: dstBufferSize)
            defer { dstBuffer.deallocate() }

            stream.src_ptr = srcPointer
            stream.src_size = srcBuffer.count
            stream.dst_ptr = dstBuffer
            stream.dst_size = dstBufferSize

            var output = Data()

            repeat {
                status = compression_stream_process(&stream, Int32(COMPRESSION_STREAM_FINALIZE.rawValue))

                switch status {
                case COMPRESSION_STATUS_OK, COMPRESSION_STATUS_END:
                    let produced = dstBufferSize - stream.dst_size
                    if produced > 0 {
                        output.append(dstBuffer, count: produced)
                    }
                    stream.dst_ptr = dstBuffer
                    stream.dst_size = dstBufferSize
                default:
                    throw operation == COMPRESSION_STREAM_ENCODE ? Errors.compressionFailed : Errors.decompressionFailed
                }
            } while status == COMPRESSION_STATUS_OK

            return output
        }
    }
    
}
