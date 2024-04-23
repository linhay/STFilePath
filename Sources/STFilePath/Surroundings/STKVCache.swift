//
//  STKVCache.swift
//
//  Created by STKVCache on 10/1/22.
//
//  From: https://www.swiftbysundell.com/articles/caching-in-swift/

import Foundation

// MARK: - Cache

public final class STKVCache<Key: Hashable, Value> {
    
    private let wrapped = NSCache<WrappedKey, Entry>()
    private let dateProvider: () -> Date
    private let keyTracker = KeyTracker()
        
    public init(dateProvider: @escaping () -> Date = Date.init,
                maximumEntryCount: Int = .max) {
        self.dateProvider = dateProvider
        wrapped.countLimit = maximumEntryCount
        wrapped.delegate = keyTracker
        
    }

}

public extension STKVCache {
    
     func value(of key: Key) -> Value? {
        return entry(forKey: key)?.value
    }
    
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
    
     func update(_ value: Value, forKey key: Key) {
        if self.value(of: key) != nil {
            remove(by: key)
        }
        insert(value, forKey: key)
    }
    
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
    
    func saveToDisk(with file: STFile, encoder: JSONEncoder = .init()) throws {
        let data = try encoder.encode(self)
        try file.overlay(with: data)
    }
    
    static func decode(from file: STFile, decoder: JSONDecoder = .init()) throws -> Self {
        let data  = try file.data()
       return try decoder.decode(Self.self, from: data)
    }
    
}
