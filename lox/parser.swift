//
//  parser.swift
//  lox
//
//  Created by Manu Harju on 6.6.2021.
//

import Foundation

enum ParserError : Error {
    case ParseError(token: Token, message: String)
}

class Parser {
    let tokens: [Token]
    var current: Int = 0
    
    init(tokens: [Token]) {
        self.tokens = tokens
    }
    
    func isAtEnd() -> Bool {
        return peek().type == TokenType.eof
    }
    
    func peek() -> Token {
        return tokens[current]
    }
    
    func previous() -> Token {
        return tokens[current - 1]
    }
    
    func advance() -> Token {
        if (!isAtEnd()) {
            current += 1
        }
        return previous()
    }
    
    func match(_ types: TokenType...) -> Bool {
        // match to any
        for type in types {
            if check(type: type) {
                let _ = advance()
                return true
            }
        }
        
        return false
    }
    
    func check(type: TokenType) -> Bool {
        if isAtEnd() {
            return false
        }
        
        return peek().type == type
    }
    
    func consume(type: TokenType, message: String) throws -> Token? {
        if check(type: type) {
            return advance()
        }
        
        throw error(token: peek(), message: message)
    }
    
    func error(token: Token, message: String) -> ParserError {
        Lox.error(token: token, message: message)
        return ParserError.ParseError(token: token, message: message)
    }
    
    func expression() throws -> Expr {
        return try equality()
    }
    
    func equality() throws -> Expr {
        var expr = try comparison()
        
        while match(TokenType.bang_equal, TokenType.equal_equal) {
            let op = previous()
            let right = try comparison()
            expr = LoxAst.Binary(left: expr, op: op, right: right)
        }
        
        return expr
    }
    
    func comparison() throws -> Expr {
        var expr = try term()
        
        while match(TokenType.greater, TokenType.greater_equal, TokenType.less, TokenType.less_equal) {
            let op = previous()
            let right = try term()
            expr = LoxAst.Binary(left: expr, op: op, right: right)
        }
        
        return expr
    }
    
    func term() throws -> Expr {
        var expr = try factor()
        
        while match(TokenType.minus, TokenType.plus) {
            let op = previous()
            let right = try factor()
            expr = LoxAst.Binary(left: expr, op: op, right: right)
        }
        
        return expr
    }
    
    func factor() throws -> Expr {
        var expr = try unary()
        
        while match(TokenType.slash, TokenType.star) {
            let op = previous()
            let right = try unary()
            expr = LoxAst.Binary(left: expr, op: op, right: right)
        }
        
        return expr
    }
    
    func unary() throws -> Expr {
        if match(TokenType.bang, TokenType.minus) {
            let op = previous()
            let right = try unary()
            return LoxAst.Unary(op: op, right: right)
        }
        
        return try primary()
    }
    
    func primary() throws -> Expr {
        if match(TokenType.kw_false)    { return LoxAst.Literal(value: false) }
        if match(TokenType.kw_true)     { return LoxAst.Literal(value: true) }
        if match(TokenType.kw_nil)      { return LoxAst.Literal(value: nil) }
        
        if match(TokenType.number, TokenType.string) {
            return LoxAst.Literal(value: previous().literal)
        }
        
        if match(TokenType.left_paren) {
            let expr = try expression()
            let _ = try consume(type: TokenType.right_paren, message: "Expect ')' after an expression.")
            return LoxAst.Grouping(expr: expr)
        }
        
        // this shouldn't happen
        throw error(token: peek(), message: "Expect expression.")
    }
    
    func parse() -> Expr? {
        do {
            let expr = try expression()
            return expr
        } catch {
            return nil
        }
    }
}
