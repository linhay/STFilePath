//
//  File.swift
//  
//
//  Created by linhey on 2022/9/6.
//

import Foundation

/**
 多文件组织缓存管理.
 */
public protocol STFileCacheReader {
    associatedtype Model
    func read(_ file: STFile) throws -> Model
}

public protocol STFileCacheWriter {
    associatedtype Model
    func write(_ model: Model, to file: STFile) throws
}

public protocol STFileCacheKeyGenerator {
    associatedtype Token
    associatedtype Model
    func key(pwd: STFolder, token: Token) throws -> String
}

public typealias STFilCacheCalculator = STFileCacheWriter & STFileCacheReader & STFileCacheKeyGenerator

open class STMultiFileCache<Calculator: STFilCacheCalculator> {
    
    public let pwd: STFolder
    public let calculator: Calculator
    
    public init(pwd: STFolder, calculator: Calculator) {
        self.pwd = pwd
        self.calculator = calculator
        _ = try? self.pwd.create()
    }
    
    open func save(_ model: Calculator.Model, for token: Calculator.Token) throws {
        let key = try calculator.key(pwd: pwd, token: token)
        let file = pwd.file(key)
        try calculator.write(model, to: file)
    }
    
    open func get(_ token: Calculator.Token) throws -> Calculator.Model {
        let key = try calculator.key(pwd: pwd, token: token)
        let file = pwd.file(key)
        return try calculator.read(file)
    }
    
}
