//
//  interpreter.swift
//  lox
//
//  Created by Manu Harju on 5.6.2021.
//

import Foundation



class Interpreter {
    var hadError: Bool = false
    
    init() {
        
    }
    
    static func error(line: Int, message: String) {
        report(line: line, error_cause: "", message: message)
    }
    
    static func error(token: Token, message: String) {
        if token.type == TokenType.eof {
            report(line: token.line, error_cause: " at end", message: message)
        } else {
            report(line: token.line, error_cause: " at '\(token.lexeme)'", message: message)
        }
    }
    
    static func report(line: Int, error_cause: String, message: String) {
        print("[line \(line)] Error\(error_cause): \(message)")
    }
    
    func run(source: String) {
        let lexer = Lexer(source: source)
        let tokens = lexer.scanTokens()
        let parser = Parser(tokens: tokens)
        let expr = parser.parse()
        
        if hadError {
            return
        }
        
        
    }
}
