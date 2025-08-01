//
//  STKVCache.swift
//
//  Created by STKVCache on 10/1/22.
//
//  From: https://www.swiftbysundell.com/articles/caching-in-swift/

import Foundation

// MARK: - Cache

/// [en] A key-value cache that can store values in memory and on disk.
/// [zh] 一个键值缓存，可以将值存储在内存和磁盘上。
public final class STKVCache<Key: Hashable, Value> {
    
    private let wrapped = NSCache<WrappedKey, Entry>()
    private let dateProvider: () -> Date
    private let keyTracker = KeyTracker()
        
    /// [en] Initializes a new `STKVCache` instance.
    /// [zh] 初始化一个新的 `STKVCache` 实例。
    /// - Parameters:
    ///   - dateProvider: A closure that provides the current date.
    ///   - maximumEntryCount: The maximum number of entries to store in the cache.
    public init(dateProvider: @escaping () -> Date = Date.init,
                maximumEntryCount: Int = .max) {
        self.dateProvider = dateProvider
        wrapped.countLimit = maximumEntryCount
        wrapped.delegate = keyTracker
        
    }

}

public extension STKVCache {
    
    /// [en] Returns the value for the given key.
    /// [zh] 返回给定键的值。
    /// - Parameter key: The key to look up.
    /// - Returns: The value for the key, or `nil` if the key is not in the cache.
     func value(of key: Key) -> Value? {
        return entry(forKey: key)?.value
    }
    
    /// [en] Inserts a value into the cache.
    /// [zh] 将一个值插入缓存。
    /// - Parameters:
    ///   - value: The value to insert.
    ///   - key: The key to associate with the value.
    ///   - lifeTime: The lifetime of the value in the cache. If `nil`, the value will not expire.
     func insert(_ value: Value, forKey key: Key, lifeTime: TimeInterval? = nil) {
        let date: Date?
        if let lifeTime = lifeTime {
            date = dateProvider().addingTimeInterval(lifeTime)
        } else {
            date = nil
        }
        let entry = Entry(key: key, value: value, expirationDate: date)
        wrapped.setObject(entry, forKey: WrappedKey(key))
        keyTracker.keys.insert(key)
    }
    
    /// [en] Updates the value for the given key.
    /// [zh] 更新给定键的值。
    /// - Parameters:
    ///   - value: The new value.
    ///   - key: The key to update.
     func update(_ value: Value, forKey key: Key) {
        if self.value(of: key) != nil {
            remove(by: key)
        }
        insert(value, forKey: key)
    }
    
    /// [en] Removes the value for the given key.
    /// [zh] 删除给定键的值。
    /// - Parameter key: The key to remove.
     func remove(by key: Key) {
        wrapped.removeObject(forKey: WrappedKey(key))
    }
    
}

// MARK: - Cache Subscript
public extension STKVCache {
    
    subscript(key: Key) -> Value? {
        get { value(of: key) }
        set {
            guard let value = newValue else {
                remove(by: key)
                return
            }
            
            insert(value, forKey: key)
        }
    }
}

// MARK: Cache.WrappedKey

private extension STKVCache {
    
    final class WrappedKey: NSObject {
        let key: Key
        
        init(_ key: Key) { self.key = key }
        
        override var hash: Int { key.hashValue }
        
        override func isEqual(_ object: Any?) -> Bool {
            guard let value = object as? WrappedKey else {
                return false
            }
            return value.key == key
        }
    }
}

// MARK: Cache.Entry

private extension STKVCache {
    
    final class Entry {
        let key: Key
        let value: Value
        let expirationDate: Date?
        
        init(key: Key, value: Value, expirationDate: Date?) {
            self.key = key
            self.value = value
            self.expirationDate = expirationDate
        }
    }
    
}

// MARK: Cache.KeyTracker

private extension STKVCache {
    
    final class KeyTracker: NSObject, NSCacheDelegate {
        var keys = Set<Key>()
        
        func cache(_: NSCache<AnyObject, AnyObject>, willEvictObject obj: Any) {
            guard let entry = obj as? Entry else {
                return
            }
            keys.remove(entry.key)
        }
    }
    
}

// MARK: - Cache.Entry + Codable

extension STKVCache.Entry: Codable where Key: Codable, Value: Codable {}

private extension STKVCache {
    
    func entry(forKey key: Key) -> Entry? {
        guard let entry = wrapped.object(forKey: WrappedKey(key)) else {
            return nil
        }

        if let expirationDate = entry.expirationDate,
           dateProvider() >= expirationDate {
            remove(by: key)
            return nil
        }
        
        return entry
    }
    
    func insert(_ entry: Entry) {
        wrapped.setObject(entry, forKey: WrappedKey(entry.key))
        keyTracker.keys.insert(entry.key)
    }
}

// MARK: - Cache + Codable

extension STKVCache: Codable where Key: Codable, Value: Codable {
    
    public convenience init(from decoder: Decoder) throws {
        self.init()
        let container = try decoder.singleValueContainer()
        let entries = try container.decode([Entry].self)
        entries.forEach(insert)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(keyTracker.keys.compactMap(entry))
    }
    
}

// MARK: - Cache Save To Disk

public extension STKVCache where Key: Codable, Value: Codable {
    
    /// [en] Saves the cache to disk.
    /// [zh] 将缓存保存到磁盘。
    /// - Parameters:
    ///   - file: The file to save the cache to.
    ///   - encoder: The encoder to use.
    /// - Throws: An error if the cache cannot be saved.
    func saveToDisk(with file: STFile, encoder: JSONEncoder = .init()) throws {
        let data = try encoder.encode(self)
        try file.overlay(with: data)
    }
    
    /// [en] Decodes a cache from a file.
    /// [zh] 从文件解码缓存。
    /// - Parameters:
    ///   - file: The file to decode the cache from.
    ///   - decoder: The decoder to use.
    /// - Returns: The decoded cache.
    /// - Throws: An error if the cache cannot be decoded.
    static func decode(from file: STFile, decoder: JSONDecoder = .init()) throws -> Self {
        let data  = try file.data()
       return try decoder.decode(Self.self, from: data)
    }
    
}

