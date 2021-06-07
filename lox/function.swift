//
//  function.swift
//  lox
//
//  Created by Manu Harju on 7.6.2021.
//

import Foundation

class Function: Callable {
    
    let declaration: LoxAst.FuncStmt
    
    init (declaration: LoxAst.FuncStmt) {
        self.declaration = declaration
    }
    
    func arity() -> Int {
        return declaration.params.count
    }

    func call(interpreter: Interpreter, args: [Any?]) throws -> Any? {
        let environment = Environment(enclosing: interpreter.globals)
        
        for i in 0..<args.count {
            environment.define(name: declaration.params[i].lexeme, value: args[i])
        }
 
        do {
            try interpreter.executeBlock(statements: declaration.body, environment: environment)
        } catch InterpreterError.Return(let value) {
            return value
        }
        return nil
    }
    
    public var description: String {
        return "<fn \(declaration.name.lexeme)>"
    }
}
