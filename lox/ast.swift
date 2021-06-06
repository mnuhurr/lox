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
    func visitBinaryExpr(binary: LoxAst.Binary) throws -> Any?
    func visitGroupingExpr(grouping: LoxAst.Grouping) throws -> Any?
    func visitLiteralExpr(literal: LoxAst.Literal) throws -> Any?
    func visitUnaryExpr(unary: LoxAst.Unary) throws -> Any?
    func visitVariable(variable: LoxAst.Variable) throws -> Any?
}

protocol StmtVisitor {
    func visitPrintStmt(printStmt: LoxAst.PrintStmt) throws -> Any?
    func visitExprStmt(exprStmt: LoxAst.ExpressionStmt) throws -> Any?
    func visitVarStmt(varStmt: LoxAst.VarStmt) throws -> Any?
}

struct LoxAst {
    // prevent creating a LoxAst object
    private init() { }
    
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
}


