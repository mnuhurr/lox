//
//  environment.swift
//  lox
//
//  Created by Manu Harju on 6.6.2021.
//

import Foundation


class Environment {
    var values: [String: Any?] = [:]
    
    init() {
    }
    
    func define(name: String, value: Any?) {
        values[name] = value
    }
    
    func get(name: Token) throws -> Any? {
        if let value = values[name.lexeme] {
            return value
        } else {
            throw InterpreterError.RuntimeError(token: name, message: "Undefined variable name '\(name.lexeme)',")
        }
    }
}
