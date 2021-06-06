//
//  interpreter.swift
//  lox
//
//  Created by Manu Harju on 6.6.2021.
//

import Foundation

enum InterpreterError : Error {
    case RuntimeError(token: Token, message: String)
}

class Interpreter: ExprVisitor, StmtVisitor {
    var hadRuntimeError: Bool = false
    
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

    func visitUnary(unary: LoxAst.Unary) throws -> Any? {
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
            return !isTruthy(object: right)
            
        default:
            return nil
        }
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
    
    func isTruthy(object: Any?) -> Bool {
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
    
    func visitPrintStmt(printStmt: LoxAst.Print) throws -> Any? {
        let value = try evaluate(expr: printStmt.expr)
        
        if value == nil {
            return nil
        }
        
        if let strval = value as? String {
            print(strval)
        } else if let dblval = value as? Double {
            print(String(dblval))
        }
        
        return nil
    }
    
    func visitExprStmt(exprStmt: LoxAst.Expression) throws  -> Any? {
        return try evaluate(expr: exprStmt.expr)
    }
}
