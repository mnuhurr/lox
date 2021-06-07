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
    
    func consume(type: TokenType, message: String) throws -> Token {
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
        return try assignment()
    }
    
    func assignment() throws -> Expr {
        let expr = try or()
        
        if match(TokenType.equal) {
            let equals = previous()
            let value = try assignment()
            
            if let varExpr = expr as? LoxAst.Variable {
                return LoxAst.Assign(name: varExpr.name, value: value)
            } else {
                // not a big deal, no need to throw, just report
                let _ = error(token: equals, message: "Invalid assignment target.")
            }
        }
        
        return expr
    }
    
    func or() throws -> Expr {
        var expr = try and()
        
        while match(TokenType.kw_or) {
            let op = previous()
            let right = try and()
            expr = LoxAst.Logical(left: expr, op: op, right: right)
        }
        
        return expr
    }
    
    func and() throws -> Expr {
        var expr = try equality()
        
        while match(TokenType.kw_and) {
            let op = previous()
            let right = try equality()
            expr = LoxAst.Logical(left: expr, op: op, right: right)
        }
        
        return expr
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
        
        return try call()
    }
    
    func call() throws -> Expr {
        var expr = try primary()
        
        while true {
            if match(TokenType.left_paren) {
                expr = try finishCall(callee: expr)
            } else {
                break
            }
        }
        
        return expr
    }
    
    func finishCall(callee: Expr) throws -> Expr {
        var args: [Expr] = []
        
        // not the most elegant way of parsing the argument list
        if !check(type: TokenType.right_paren) {
            args.append(try expression())
            
            while match(TokenType.comma) {
                args.append(try expression())
                
                if args.count >= 255 {
                    let _ = error(token: peek(), message: "Can't have more than 255 arguments.")
                }
            }
        }
        
        let paren = try consume(type: TokenType.right_paren, message: "Expect ')' after arguments.")
        
        return LoxAst.Call(callee: callee, paren: paren, args: args)
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
        if match(TokenType.kw_if) {
            return try ifStatement()
        }
        
        if match(TokenType.kw_print) {
            return try printStatement()
        }
        
        if match(TokenType.kw_return) {
            return try returnStatement()
        }
        
        if match(TokenType.kw_while) {
            return try whileStatement()
        }
        
        if match(TokenType.kw_for) {
            return try forStatement()
        }
        
        if match(TokenType.left_brace) {
            let stmts = try block()
            return LoxAst.Block(statements: stmts)
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
    
    func ifStatement() throws -> Stmt {
        let _ = try consume(type: TokenType.left_paren, message: "Expect '(' after 'if'.")
        let condition = try expression()
        let _ = try consume(type: TokenType.right_paren, message: "Expect ')' after if condition.")
        
        let thenBranch = try statement()
        var elseBranch: Stmt? = nil
        if match(TokenType.kw_else) {
            elseBranch = try statement()
        }
        
        return LoxAst.IfStmt(condition: condition, thenBranch: thenBranch, elseBranch: elseBranch)
    }
    
    func whileStatement() throws -> Stmt {
        let _ = try consume(type: TokenType.left_paren, message: "Expect '(' after 'while'.")
        let condition = try expression()
        let _ = try consume(type: TokenType.right_paren, message: "Expect ')' after condition.")
        let body = try statement()
        
        return LoxAst.WhileStmt(condition: condition, body: body)
    }
    
    func forStatement() throws -> Stmt {
        // parse and convert for into while
        let _ = try consume(type: TokenType.left_paren, message: "Expect '(' after 'for'.")
        
        // parse: for (initializer; condition; increment) { ... }
        
        // 1. initializer
        var initializer: Stmt?
        
        if match(TokenType.semicolon) {
            initializer = nil
        } else if match(TokenType.kw_var) {
            initializer = try varDeclaration()
        } else {
            initializer = try expressionStatement()
        }
        
        // 2. condition
        var condition: Expr? = nil
        if !check(type: TokenType.semicolon) {
            condition = try expression()
        }
        let _ = try consume(type: TokenType.semicolon, message: "Expect ';' after loop condition.")
        
        // 3. increment
        var increment: Expr? = nil
        if !check(type: TokenType.right_paren) {
            increment = try expression()
        }
        let _ = try consume(type: TokenType.right_paren, message: "Expect ')' after for clause.")
        var body = try statement()

        // start converting/syntax desugaring
        if increment != nil {
            body = LoxAst.Block(statements: [body, LoxAst.ExpressionStmt(expr: increment!)])
        }
        
        if condition == nil {
            condition = LoxAst.Literal(value: true)
        }
                
        body = LoxAst.WhileStmt(condition: condition!, body: body)

        // if there is an initializer, add it before everything
        if initializer != nil {
            body = LoxAst.Block(statements: [initializer!, body])
        }

        return body
    }
    
    func block() throws -> [Stmt] {
        var statements: [Stmt] = []
        
        while !check(type: TokenType.right_brace) && !isAtEnd() {
            let stmt = try declaration()
            if stmt != nil {
                statements.append(stmt!)
            }
        }
        
        let _ = try consume(type: TokenType.right_brace, message: "Expect '}' after a block.")
        return statements
    }
    
    func declaration() throws -> Stmt? {
        do {
            if match(TokenType.kw_fun) {
                return try function(kind: "function")
            }
            
            if match(TokenType.kw_var) {
                return try varDeclaration()
            }
            
            return try statement()
            
        } catch {
            synchronize()
        }
        return nil
    }
    
    func function(kind: String) throws -> LoxAst.FuncStmt {
        let name = try consume(type: TokenType.identifier, message: "Expect \(kind) name.")
        
        let _ = try consume(type: TokenType.left_paren, message: "Expect '(' after \(kind) name")
        
        var params: [Token] = []
        if !check(type: TokenType.right_paren) {
            params.append(try consume(type: TokenType.identifier, message: "Expect parameter name."))
            
            while match(TokenType.comma) {
                params.append(try consume(type: TokenType.identifier, message: "Expect parameter name."))
                
                if params.count >= 255 {
                    let _ = error(token: peek(), message: "Can't have more than 255 params.")
                }
            }
        }
        
        let _ = try consume(type: TokenType.right_paren, message: "Expect ')' after parameters.")
        
        // function body
        let _ = try consume(type: TokenType.left_brace, message: "Expect '{' before \(kind) body.")
        let body = try block()
        return LoxAst.FuncStmt(name: name, params: params, body: body)
    }
    
    func returnStatement() throws -> Stmt {
        let keyword = previous()
        var value: Expr? = nil
        
        if !check(type: TokenType.semicolon) {
            value = try expression()
        }
        
        let _ = try consume(type: TokenType.semicolon, message: "Expect ';' after return value.")
        return LoxAst.ReturnStmt(keyword: keyword, value: value)
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
