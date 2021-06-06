//
//  token.swift
//  lox
//
//  Created by Manu Harju on 6.6.2021.
//

import Foundation


enum TokenType {
    // single character tokens
    case left_paren, right_paren, left_brace, right_brace, comma, dot, minus, plus, semicolon, slash, star
    
    // one or two characters
    case bang, bang_equal, equal, equal_equal, greater, greater_equal, less, less_equal
    
    // literals
    case identifier, string, number
    
    // keywords
    case kw_and, kw_class, kw_else, kw_false, kw_fun, kw_for, kw_if, kw_nil, kw_or, kw_print, kw_return
    case kw_super, kw_this, kw_true, kw_var, kw_while
    
    case eof
}

struct Token {
    let type: TokenType
    let lexeme: String
    let literal: Any?
    let line: Int
    
    init(type: TokenType, lexeme: String, literal: Any?, line: Int) {
        self.type = type
        self.lexeme = lexeme
        self.literal = literal
        self.line = line
    }
    
    var description: String {
        var literal_string = ""
        
        if literal != nil {
            literal_string = " literal=" + String(describing: literal!)
        }
        
        return "Token type=\(type) lexeme=\(lexeme)\(literal_string)"
    }
}
