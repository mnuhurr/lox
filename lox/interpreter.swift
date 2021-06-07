//
//  interpreter.swift
//  lox
//
//  Created by Manu Harju on 6.6.2021.
//

import Foundation

enum InterpreterError : Error {
    case RuntimeError(token: Token, message: String)
    case Return(value: Any?)
}

protocol Callable {
    func arity() -> Int
    func call(interpreter: Interpreter, args: [Any?]) throws -> Any?
}

class Interpreter: ExprVisitor, StmtVisitor {
    var hadRuntimeError: Bool = false
    let globals: Environment = Environment()
    var environment: Environment
    
    init() {
        environment = globals
    }
    
    func interpret(statements: [Stmt]) {
        
        do {
            for statement in statements {
                let _ = try execute(stmt: statement)
            }
        } catch InterpreterError.RuntimeError(let token, let message) {
            Lox.error(token: token, message: message)
            hadRuntimeError = true
        } catch {
            print("An unknown error occurred: \(error)")
        }
        
    }
    
    func execute(stmt: Stmt) throws -> Any? {
        return try stmt.accept(visitor: self)
    }
    
    func evaluate(expr: Expr) throws -> Any? {
        return try expr.accept(visitor: self)
    }
    
    func visitLiteralExpr(literal: LoxAst.Literal) -> Any? {
        return literal.value
    }

    func visitGroupingExpr(grouping: LoxAst.Grouping) throws -> Any? {
        return try evaluate(expr: grouping.expr)
    }

    func visitCallExpr(call: LoxAst.Call) throws -> Any? {
        let callee = try evaluate(expr: call.callee)
        
        var args: [Any?] = []
        
        for arg in call.args {
            args.append(try evaluate(expr: arg))
        }
        
        if let function = callee as? Callable {
            if args.count != function.arity() {
                throw InterpreterError.RuntimeError(token: call.paren, message:
                                                        "Expected \(function.arity()) arguments but got \(args.count).")
            }
            
            return try function.call(interpreter: self, args: args)
        } else {
            throw InterpreterError.RuntimeError(token: call.paren, message: "Can only call functions and classes.")
        }
    }
    
    func visitUnaryExpr(unary: LoxAst.Unary) throws -> Any? {
        let right = try evaluate(expr: unary.right)

        switch unary.op.type {
        case TokenType.minus:
            if let d = right as? Double {
                return -d
            } else {
                // wat do? warning?
                return nil
            }
            
        case TokenType.bang:
            return !isTruthy(right)
            
        default:
            return nil
        }
    }
    
    func visitAssignExpr(assign: LoxAst.Assign) throws -> Any? {
        let value = try evaluate(expr: assign.value)
        try environment.assign(name: assign.name, value: value)
        return value;
    }
    
    func visitBinaryExpr(binary: LoxAst.Binary) throws -> Any? {
        let left = try evaluate(expr: binary.left)
        let right = try evaluate(expr: binary.right)
        
        let d_left = left as? Double
        let d_right = right as? Double

        switch binary.op.type {
        case TokenType.minus:
            if d_left != nil && d_right != nil {
                return d_left! - d_right!
            } else {
                throw InterpreterError.RuntimeError(token: binary.op, message: "Operands must be numbers.")
            }
            
        case TokenType.slash:
            if d_left != nil && d_right != nil {
                return d_left! / d_right!
            } else {
                throw InterpreterError.RuntimeError(token: binary.op, message: "Operands must be numbers.")
            }
            
        case TokenType.star:
            if d_left != nil && d_right != nil {
                return d_left! * d_right!
            } else {
                throw InterpreterError.RuntimeError(token: binary.op, message: "Operands must be numbers.")
            }

        case TokenType.plus:
            if d_left != nil && d_right != nil {
                return d_left! + d_right!
            } else {
                let str_left = left as? String
                let str_right = right as? String
                
                if str_left != nil && str_right != nil {
                    return str_left! + str_right!
                } else if d_left != nil && str_right != nil {
                    return String(d_left!) + str_right!
                } else if str_left != nil && d_right != nil {
                    return str_left! + String(d_right!)
                } else {
                    throw InterpreterError.RuntimeError(token: binary.op, message: "Operands must be two numbers or two strings.")
                }
            }
            
        case TokenType.greater:
            if d_left != nil && d_right != nil {
                return d_left! > d_right!
            } else {
                throw InterpreterError.RuntimeError(token: binary.op, message: "Operands must be numbers.")
            }

        case TokenType.greater_equal:
            if d_left != nil && d_right != nil {
                return d_left! >= d_right!
            } else {
                throw InterpreterError.RuntimeError(token: binary.op, message: "Operands must be numbers.")
            }

        case TokenType.less:
            if d_left != nil && d_right != nil {
                return d_left! < d_right!
            } else {
                throw InterpreterError.RuntimeError(token: binary.op, message: "Operands must be numbers.")
            }
            
        case TokenType.less_equal:
            if d_left != nil && d_right != nil {
                return d_left! <= d_right!
            } else {
                throw InterpreterError.RuntimeError(token: binary.op, message: "Operands must be numbers.")
            }

        case TokenType.equal_equal:
            return isEqual(left, right)
            
        case TokenType.bang_equal:
            return !isEqual(left, right)
            
        default:
            // wat do
            break
        }
        
        return nil
    }
    
    func visitLogicalExpr(logical: LoxAst.Logical) throws -> Any? {
        let left = try evaluate(expr: logical.left)
        
        if logical.op.type == TokenType.kw_or {
            if isTruthy(left) {
                return left
            }
        } else {
            if !isTruthy(left) {
                return left
            }
        }
        
        return try evaluate(expr: logical.right)
    }
        
    func visitVariable(variable: LoxAst.Variable) throws -> Any? {
        return try environment.get(name: variable.name)
    }
    
    func isTruthy(_ object: Any?) -> Bool {
        // check if object == 0 ???
        if object == nil {
            return false
        } else if let boolean_value = object as? Bool {
            return boolean_value
        } else {
            return true
        }
    }
    
    func isEqual(_ left: Any?, _ right: Any?) -> Bool {
        if left == nil && right == nil {
            return true
        }
        
        if left == nil || right == nil {
            return false
        }
        
        // test for numbers
        let dbl_left = left as? Double
        let dbl_right = right as? Double
        
        if dbl_left != nil && dbl_right != nil {
            return dbl_left == dbl_right
        }
        
        // test for strings
        let str_left = left as? String
        let str_right = right as? String
        
        if str_left != nil && str_right != nil {
            return str_left == str_right
        }
        
        // test for booleans
        let b_left = left as? Bool
        let b_right = right as? Bool
        
        if b_left != nil && b_right != nil {
            return b_left == b_right
        }
        
        return false
    }
    
    func visitPrintStmt(printStmt: LoxAst.PrintStmt) throws -> Any? {
        let value = try evaluate(expr: printStmt.expr)
        
        if value == nil {
            return nil
        }
        
        if let strval = value as? String {
            print(strval)
        } else if let dblval = value as? Double {
            print(String(dblval))
        } else if let bval = value as? Bool {
            print(String(bval))
        }
        
        return nil
    }
    
    func visitExprStmt(exprStmt: LoxAst.ExpressionStmt) throws -> Any? {
        return try evaluate(expr: exprStmt.expr)
    }
    
    func visitVarStmt(varStmt: LoxAst.VarStmt) throws -> Any? {
        var value: Any? = nil
        
        if varStmt.initializer != nil {
            value = try evaluate(expr: varStmt.initializer!)
        }
        
        environment.define(name: varStmt.name.lexeme, value: value)
        return nil
    }
    
    func visitBlock(block: LoxAst.Block) throws -> Any? {
        try executeBlock(statements: block.statements, environment: Environment(enclosing: environment))
        return nil
    }
    
    func executeBlock(statements: [Stmt], environment: Environment) throws {
        let previous: Environment = self.environment
        
        self.environment = environment
        defer {
            self.environment = previous
        }

        for stmt in statements {
            let _ = try execute(stmt: stmt)
        }
        
    }
    
    func visitIfStmt(ifStmt: LoxAst.IfStmt) throws -> Any? {
        if isTruthy(try evaluate(expr: ifStmt.condition)) {
            return try execute(stmt: ifStmt.thenBranch)
        } else if ifStmt.elseBranch != nil {
            return try execute(stmt: ifStmt.elseBranch!)
        }
        
        return nil
    }
    
    func visitWhileStmt(whileStmt: LoxAst.WhileStmt) throws -> Any? {
        while isTruthy(try evaluate(expr: whileStmt.condition)) {
            let _ = try execute(stmt: whileStmt.body)
        }
        return nil
    }
    
    func visitFuncStmt(funcStmt: LoxAst.FuncStmt) throws -> Any? {
        let function = Function(declaration: funcStmt)
        environment.define(name: funcStmt.name.lexeme, value: function)
        return nil
    }
    
    func visitReturnStmt(returnStmt: LoxAst.ReturnStmt) throws -> Any? {
        var value: Any? = nil
        
        if let return_expr = returnStmt.value {
            value = try evaluate(expr: return_expr)
        }
        
        throw InterpreterError.Return(value: value)
    }
}
