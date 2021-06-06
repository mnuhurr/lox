//
//  environment.swift
//  lox
//
//  Created by Manu Harju on 6.6.2021.
//

import Foundation


class Environment {
    var values: [String: Any?] = [:]
    let enclosing: Environment?
    
    init() {
        self.enclosing = nil
    }
    
    init(enclosing: Environment) {
        self.enclosing = enclosing
    }
    
    func define(name: String, value: Any?) {
        values[name] = value
    }
    
    func get(name: Token) throws -> Any? {
        if let value = values[name.lexeme] {
            return value
        } else if enclosing != nil {
            return try enclosing!.get(name: name)
        } else {
            throw InterpreterError.RuntimeError(token: name, message: "Undefined variable name '\(name.lexeme)',")
        }
    }
    
    func assign(name: Token, value: Any?) throws {
        if let _ = values[name.lexeme] {
            values[name.lexeme] = value
        } else if enclosing != nil {
            try enclosing!.assign(name: name, value: value)
        } else {
            throw InterpreterError.RuntimeError(token: name, message: "Undefined variable: '\(name.lexeme)'.")
        }
    }
}
