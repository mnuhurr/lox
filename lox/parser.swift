//
//  parser.swift
//  lox
//
//  Parse tokens and construct an AST
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
        
        if match(TokenType.identifier) {
            return LoxAst.Variable(name: previous())
        }
        
        if match(TokenType.left_paren) {
            let expr = try expression()
            let _ = try consume(type: TokenType.right_paren, message: "Expect ')' after an expression.")
            return LoxAst.Grouping(expr: expr)
        }
        
        // this shouldn't happen ?
        throw error(token: peek(), message: "Expect expression.")
    }
    
    func statement() throws -> Stmt {
        if match(TokenType.kw_print) {
            return try printStatement()
        }
        
        return try expressionStatement()
    }
    
    func printStatement() throws -> Stmt {
        let value: Expr = try expression()
        let _ = try consume(type: TokenType.semicolon, message: "Expect ';' after value.")
        return LoxAst.PrintStmt(expr: value)
    }
    
    func expressionStatement() throws -> Stmt {
        let expr: Expr = try expression()
        let _ = try consume(type: TokenType.semicolon, message: "Expect ';' after value.")
        return LoxAst.ExpressionStmt(expr: expr)
    }
    
    func declaration() throws -> Stmt? {
        do {
            if match(TokenType.kw_var) {
                return try varDeclaration()
            }
            
            return try statement()
            
        } catch {
            synchronize()
        }
        return nil
    }
    
    func varDeclaration() throws -> Stmt {
        let name: Token? = try consume(type: TokenType.identifier, message: "Expect variable name.")
        var initializer: Expr? = nil
        
        if match(TokenType.equal) {
            initializer = try expression()
        }
        
        let _ = try consume(type: TokenType.semicolon, message: "Expect ';' after variable declaration.")
        return LoxAst.VarStmt(name: name!, initializer: initializer)
    }
    
    func parse() -> [Stmt] {
        var statements: [Stmt] = []
        
        while (!isAtEnd()) {
            let stmt = try? declaration()
            if stmt != nil {
                statements.append(stmt!)
            } else {
                // wat do
            }
        }
        
        return statements
    }
    
    // find the start of the next statement
    func synchronize() {
        let _ = advance()
        
        while !isAtEnd() {
            if previous().type == TokenType.semicolon {
                return
            }
            
            switch peek().type {
            case TokenType.kw_class, TokenType.kw_fun, TokenType.kw_var, TokenType.kw_for, TokenType.kw_if,
                 TokenType.kw_while, TokenType.kw_print, TokenType.kw_return:
                return;
                
            default:
                let _ = advance()
            }
        }
    }
}
