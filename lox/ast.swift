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
    func accept(visitor: Visitor) throws -> Any?
}

protocol Visitor {
    func visitBinaryExpr(binary: LoxAst.Binary) throws -> Any?
    func visitGroupingExpr(grouping: LoxAst.Grouping) throws -> Any?
    func visitLiteralExpr(literal: LoxAst.Literal) throws -> Any?
    func visitUnary(unary: LoxAst.Unary) throws -> Any?
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
        
        func accept(visitor: Visitor) throws -> Any? {
            return try visitor.visitBinaryExpr(binary: self)
        }
    }
    
    class Grouping: Expr {
        let expr: Expr
        
        init(expr: Expr) {
            self.expr = expr
        }
        
        func accept(visitor: Visitor) throws -> Any? {
            return try visitor.visitGroupingExpr(grouping: self)
        }
    }
    
    class Literal: Expr {
        let value: Any?
        
        init(value: Any?) {
            self.value = value
        }
        
        func accept(visitor: Visitor) throws -> Any? {
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
        
        func accept(visitor: Visitor) throws -> Any? {
            return try visitor.visitUnary(unary: self)
        }
    }
}


