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
    
    static func report(line: Int, error_cause: String, message: String) {
        print("[line \(line)] Error\(error_cause): \(message)")
    }
    
    func run(source: String) {
        let lexer = Lexer(source: source)
        let tokens = lexer.scanTokens()
        
        for token in tokens {
            print(token)
        }
    }
}
