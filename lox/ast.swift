//
//  ast.swift
//  lox
//
//  Classes to represent the abstract syntax tree
//
//  Created by Manu Harju on 6.6.2021.
//

import Foundation

protocol Expr {
    func accept(visitor: ExprVisitor) throws -> Any?
}

protocol Stmt {
    func accept(visitor: StmtVisitor) throws -> Any?
}

protocol ExprVisitor {
    func visitAssignExpr(assign: LoxAst.Assign) throws -> Any?
    func visitBinaryExpr(binary: LoxAst.Binary) throws -> Any?
    func visitCallExpr(call: LoxAst.Call) throws -> Any?
    func visitGroupingExpr(grouping: LoxAst.Grouping) throws -> Any?
    func visitLiteralExpr(literal: LoxAst.Literal) throws -> Any?
    func visitLogicalExpr(logical: LoxAst.Logical) throws -> Any?
    func visitUnaryExpr(unary: LoxAst.Unary) throws -> Any?
    func visitVariable(variable: LoxAst.Variable) throws -> Any?
}

protocol StmtVisitor {
    func visitBlock(block: LoxAst.Block) throws -> Any?
    func visitPrintStmt(printStmt: LoxAst.PrintStmt) throws -> Any?
    func visitExprStmt(exprStmt: LoxAst.ExpressionStmt) throws -> Any?
    func visitVarStmt(varStmt: LoxAst.VarStmt) throws -> Any?
    func visitIfStmt(ifStmt: LoxAst.IfStmt) throws -> Any?
    func visitWhileStmt(whileStmt: LoxAst.WhileStmt) throws -> Any?
    func visitFuncStmt(funcStmt: LoxAst.FuncStmt) throws -> Any?
    func visitReturnStmt(returnStmt: LoxAst.ReturnStmt) throws -> Any?
}

struct LoxAst {
    // prevent creating a LoxAst object
    private init() { }
    
    class Assign: Expr {
        let name: Token
        let value: Expr
        
        init(name: Token, value: Expr) {
            self.name = name
            self.value = value
        }
        
        func accept(visitor: ExprVisitor) throws -> Any? {
            return try visitor.visitAssignExpr(assign: self)
        }
    }
    
    class Binary: Expr {
        let left: Expr
        let op: Token
        let right: Expr
        
        init(left: Expr, op: Token, right: Expr) {
            self.left = left
            self.op = op
            self.right = right
        }
        
        func accept(visitor: ExprVisitor) throws -> Any? {
            return try visitor.visitBinaryExpr(binary: self)
        }
    }
    
    class Call: Expr {
        let callee: Expr
        let paren: Token
        let args: [Expr]
        
        init(callee: Expr, paren: Token, args: [Expr]) {
            self.callee = callee
            self.paren = paren
            self.args = args
        }
        
        func accept(visitor: ExprVisitor) throws -> Any? {
            return try visitor.visitCallExpr(call: self)
        }
    }
    
    class Grouping: Expr {
        let expr: Expr
        
        init(expr: Expr) {
            self.expr = expr
        }
        
        func accept(visitor: ExprVisitor) throws -> Any? {
            return try visitor.visitGroupingExpr(grouping: self)
        }
    }
    
    class Literal: Expr {
        let value: Any?
        
        init(value: Any?) {
            self.value = value
        }
        
        func accept(visitor: ExprVisitor) throws -> Any? {
            return try visitor.visitLiteralExpr(literal: self)
        }
    }
    
    class Logical: Expr {
        let left: Expr
        let op: Token
        let right: Expr
        
        init(left: Expr, op: Token, right: Expr) {
            self.left = left
            self.op = op
            self.right = right
        }
        
        func accept(visitor: ExprVisitor) throws -> Any? {
            return try visitor.visitLogicalExpr(logical: self)
        }
    }
    
    class Unary: Expr {
        let op: Token
        let right: Expr
        
        init(op: Token, right: Expr) {
            self.op = op
            self.right = right
        }
        
        func accept(visitor: ExprVisitor) throws -> Any? {
            return try visitor.visitUnaryExpr(unary: self)
        }
    }
    
    class Variable: Expr {
        let name: Token
        
        init(name: Token) {
            self.name = name
        }
        
        func accept(visitor: ExprVisitor) throws -> Any? {
            return try visitor.visitVariable(variable: self)
        }
    }
    
    class ExpressionStmt: Stmt {
        let expr: Expr
        
        init(expr: Expr) {
            self.expr = expr
        }
        
        func accept(visitor: StmtVisitor) throws -> Any? {
            return try visitor.visitExprStmt(exprStmt: self)
        }
    }
    
    class Block: Stmt {
        let statements: [Stmt]
        
        init(statements: [Stmt]) {
            self.statements = statements
        }
        
        func accept(visitor: StmtVisitor) throws -> Any? {
            return try visitor.visitBlock(block: self)
        }
    }
    
    class PrintStmt: Stmt {
        let expr: Expr
        
        init(expr: Expr) {
            self.expr = expr
        }
        
        func accept(visitor: StmtVisitor) throws -> Any? {
            return try visitor.visitPrintStmt(printStmt: self)
        }
    }
    
    class VarStmt: Stmt {
        let name: Token
        let initializer: Expr?
        
        init(name: Token, initializer: Expr?) {
            self.name = name
            self.initializer = initializer
        }
        
        func accept(visitor: StmtVisitor) throws -> Any? {
            return try visitor.visitVarStmt(varStmt: self)
        }
    }
    
    class IfStmt: Stmt {
        let condition: Expr
        let thenBranch: Stmt
        let elseBranch: Stmt?
        
        init(condition: Expr, thenBranch: Stmt, elseBranch: Stmt?) {
            self.condition = condition
            self.thenBranch = thenBranch
            self.elseBranch = elseBranch
        }
        
        func accept(visitor: StmtVisitor) throws -> Any? {
            return try visitor.visitIfStmt(ifStmt: self)
        }
    }
    
    class WhileStmt: Stmt {
        let condition: Expr
        let body: Stmt
        
        init(condition: Expr, body: Stmt) {
            self.condition = condition
            self.body = body
        }
        
        func accept(visitor: StmtVisitor) throws -> Any? {
            return try visitor.visitWhileStmt(whileStmt: self)
        }
    }

    class FuncStmt: Stmt {
        let name: Token
        let params: [Token]
        let body: [Stmt]
        
        init(name: Token, params: [Token], body: [Stmt]) {
            self.name = name
            self.params = params
            self.body = body
        }

        func accept(visitor: StmtVisitor) throws -> Any? {
            return try visitor.visitFuncStmt(funcStmt: self)
        }
    }
    
    class ReturnStmt: Stmt {
        let keyword: Token
        let value: Expr?
        
        init(keyword: Token, value: Expr?) {
            self.keyword = keyword
            self.value = value
        }
        
        func accept(visitor: StmtVisitor) throws -> Any? {
            return try visitor.visitReturnStmt(returnStmt: self)
        }
    }
}


