//
//  File.swift
//  
//
//  Created by linhey on 2023/6/5.
//

import Foundation

/// [en] A struct that represents a key for `UserDefaults`.
/// [zh] 一个表示 `UserDefaults` 键的结构体。
public struct STUserDefaultsKeys: ExpressibleByStringLiteral {
    
    public let value: String
    
    public init(stringLiteral value: String) {
        self.value = value
    }
    
    public init(_ value: String) {
        self.value = value
    }
    
}

/// [en] A protocol for types that can be stored in `UserDefaults`.
/// [zh] 一个可存储在 `UserDefaults` 中的类型的协议。
public protocol STUserDefaultsValue {
    /// [en] Writes the value to `UserDefaults`.
    /// [zh] 将值写入 `UserDefaults`。
    /// - Parameters:
    ///   - userDefault: The `UserDefaults` instance to write to.
    ///   - key: The key to write the value for.
    func write(to userDefault: UserDefaults, for key: String)
    /// [en] Reads the value from `UserDefaults`.
    /// [zh] 从 `UserDefaults` 读取值。
    /// - Parameters:
    ///   - userDefault: The `UserDefaults` instance to read from.
    ///   - key: The key to read the value for.
    /// - Returns: The value, or `nil` if the value is not in `UserDefaults`.
    static func read(from userDefault: UserDefaults, for key: String) -> Self?
}

/// [en] A property wrapper for `UserDefaults`.
/// [zh] `UserDefaults` 的属性包装器。
@propertyWrapper
public struct STUserDefaults<T: STUserDefaultsValue> {
    
    let key: STUserDefaultsKeys
    let defaultValue: T
    let userDefault: UserDefaults
    
    /// [en] Initializes a new `STUserDefaults` instance.
    /// [zh] 初始化一个新的 `STUserDefaults` 实例。
    /// - Parameters:
    ///   - key: The key to store the value for.
    ///   - defaultValue: The default value to use if the key is not in `UserDefaults`.
    ///   - userDefault: The `UserDefaults` instance to use.
    public init(_ key: STUserDefaultsKeys,
                default: T,
                userDefault: UserDefaults = .standard) {
        self.key = key
        self.defaultValue = `default`
        self.userDefault = userDefault
    }
    
    public var wrappedValue: T {
        get { return T.read(from: userDefault, for: key.value) ?? defaultValue }
        set { newValue.write(to: userDefault, for: key.value) }
    }
    
}

extension STUserDefaults: Equatable where T: Equatable {
    
    public static func == (lhs: STUserDefaults, rhs: STUserDefaults) -> Bool {
        lhs.wrappedValue == rhs.wrappedValue
    }
    
}

extension Optional: STUserDefaultsValue where Wrapped: STUserDefaultsValue {
    
    public func write(to userDefault: UserDefaults, for key: String) {
        if let value = self {
            userDefault.set(value, forKey: key)
        } else {
            userDefault.set(nil, forKey: key)
        }
    }
    
    public static func read(from userDefault: UserDefaults, for key: String) -> Optional<Wrapped>? {
        guard let _ = userDefault.object(forKey: key) else { return nil }
        return Wrapped.read(from: userDefault, for: key)
    }
    
}

extension String: STUserDefaultsValue {
    
    public func write(to userDefault: UserDefaults, for key: String) {
        userDefault.set(self, forKey: key)
    }
    
    public static func read(from userDefault: UserDefaults, for key: String) -> String? {
        guard let _ = userDefault.object(forKey: key) else { return nil }
        return userDefault.string(forKey: key)
    }
}

extension Int: STUserDefaultsValue {
    
    public func write(to userDefault: UserDefaults, for key: String) {
        userDefault.set(self, forKey: key)
    }
    
    public static func read(from userDefault: UserDefaults, for key: String) -> Int? {
        guard let _ = userDefault.object(forKey: key) else { return nil }
        return userDefault.integer(forKey: key)
    }
}

extension Bool: STUserDefaultsValue {
    
    public func write(to userDefault: UserDefaults, for key: String) {
        userDefault.set(self, forKey: key)
    }
    
    public static func read(from userDefault: UserDefaults, for key: String) -> Bool? {
        guard let _ = userDefault.object(forKey: key) else { return nil }
        return userDefault.bool(forKey: key)
    }
}

extension Float: STUserDefaultsValue {
    
    public func write(to userDefault: UserDefaults, for key: String) {
        userDefault.set(self, forKey: key)
    }
    
    public static func read(from userDefault: UserDefaults, for key: String) -> Float? {
        guard let _ = userDefault.object(forKey: key) else { return nil }
        return userDefault.float(forKey: key)
    }
}

extension Double: STUserDefaultsValue {
    
    public func write(to userDefault: UserDefaults, for key: String) {
        userDefault.set(self, forKey: key)
    }
    
    public static func read(from userDefault: UserDefaults, for key: String) -> Double? {
        guard let _ = userDefault.object(forKey: key) else { return nil }
        return userDefault.double(forKey: key)
    }
}

extension URL: STUserDefaultsValue {
    
    public func write(to userDefault: UserDefaults, for key: String) {
        userDefault.set(self, forKey: key)
    }
    
    public static func read(from userDefault: UserDefaults, for key: String) -> URL? {
        guard let _ = userDefault.object(forKey: key) else { return nil }
        return userDefault.url(forKey: key)
    }
}

extension UUID: STUserDefaultsValue {
    
    public func write(to userDefault: UserDefaults, for key: String) {
        let data = try? JSONEncoder().encode(self)
        data?.write(to: userDefault, for: key)
    }
    
    public static func read(from userDefault: UserDefaults, for key: String) -> UUID? {
        guard let data = Data.read(from: userDefault, for: key) else {
            return nil
        }
        return try? JSONDecoder().decode(UUID.self, from: data)
    }
    
}

extension Data: STUserDefaultsValue {
    
    public func write(to userDefault: UserDefaults, for key: String) {
        userDefault.set(self, forKey: key)
    }
    
    public static func read(from userDefault: UserDefaults, for key: String) -> Data? {
        guard let _ = userDefault.object(forKey: key) else { return nil }
        return userDefault.data(forKey: key)
    }
}

extension Array: STUserDefaultsValue where Element: Codable {
    
    public func write(to userDefault: UserDefaults, for key: String) {
        do {
            let encoder = PropertyListEncoder()
            encoder.outputFormat = .binary
            let data = try encoder.encode(self)
            data.write(to: userDefault, for: key)
        } catch {
            debugPrint(error.localizedDescription)
        }
    }
    
    public static func read(from userDefault: UserDefaults, for key: String) -> [Element]? {
        guard let data: Data = Data.read(from: userDefault, for: key) else { return nil }
        do {
            let decoder = PropertyListDecoder()
            let array = try decoder.decode([Element].self, from: data)
            return array
        } catch {
            debugPrint(error.localizedDescription)
            return nil
        }
    }
}

extension STUserDefaultsValue where Self: Codable {
    
    public func write(to userDefault: UserDefaults, for key: String) {
        do {
            let encoder = PropertyListEncoder()
            encoder.outputFormat = .binary
            let data = try encoder.encode(self)
            data.write(to: userDefault, for: key)
        } catch {
            debugPrint(error.localizedDescription)
        }
    }
    
    public static func read(from userDefault: UserDefaults, for key: String) -> Self? {
        guard let data = userDefault.data(forKey: key) else { return nil }
        do {
            let decoder = PropertyListDecoder()
            return try decoder.decode(Self.self, from: data)
        } catch {
            debugPrint(error.localizedDescription)
            return nil
        }
    }
}
