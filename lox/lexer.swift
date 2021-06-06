//
//  lexer.swift
//  lox
//
//  Created by Manu Harju on 5.6.2021.
//

import Foundation

// extension to index individual characters
extension StringProtocol {
    subscript(offset: Int) -> Character {
        self[index(startIndex, offsetBy: offset)]
    }
}



class Lexer {
    let source: String
    
    var start: Int = 0
    var current: Int = 0
    var line: Int = 1
    
    let keywords: [String: TokenType] = [
        "and": TokenType.kw_and,
        "class": TokenType.kw_class,
        "else": TokenType.kw_else,
        "false": TokenType.kw_false,
        "for": TokenType.kw_for,
        "fun": TokenType.kw_fun,
        "if": TokenType.kw_if,
        "nil": TokenType.kw_nil,
        "or": TokenType.kw_or,
        "print": TokenType.kw_print,
        "return": TokenType.kw_return,
        "super": TokenType.kw_super,
        "this": TokenType.kw_this,
        "true": TokenType.kw_true,
        "var": TokenType.kw_var,
        "while": TokenType.kw_while
    ]
    
    init(source: String) {
        self.source = source
    }
    
    func scanTokens() -> [Token] {
        var tokens: [Token] = []

        while (!isAtEnd()) {
            start = current
            
            if let token = scanNext() {
                tokens.append(token)
            }
        }
        
        tokens.append(Token(type: TokenType.eof, lexeme: "", literal: nil, line: line))
        return tokens
    }
    
    func isAtEnd() -> Bool {
        return current >= source.count
    }
    
    func scanNext() -> Token? {
        let c = advance()
        
        switch c {
        case "(":   return makeToken(type: TokenType.left_paren, literal: nil)
        case ")":   return makeToken(type: TokenType.right_paren, literal: nil)
        case "{":   return makeToken(type: TokenType.left_brace, literal: nil)
        case "}":   return makeToken(type: TokenType.right_brace, literal: nil)
        case ",":   return makeToken(type: TokenType.comma, literal: nil)
        case ".":   return makeToken(type: TokenType.dot, literal: nil)
        case "-":   return makeToken(type: TokenType.minus, literal: nil)
        case "+":   return makeToken(type: TokenType.plus, literal: nil)
        case ";":   return makeToken(type: TokenType.semicolon, literal: nil)
        case "*":   return makeToken(type: TokenType.star, literal: nil)

        case "!":
            let token_type = match(expected: "=") ? TokenType.bang_equal : TokenType.bang
            return makeToken(type: token_type, literal: nil)
            
        case "=":
            let token_type = match(expected: "=") ? TokenType.equal_equal : TokenType.equal
            return makeToken(type: token_type, literal: nil)

        case "<":
            let token_type = match(expected: "=") ? TokenType.less_equal : TokenType.less
            return makeToken(type: token_type, literal: nil)
            
        case ">":
            let token_type = match(expected: "=") ? TokenType.greater_equal : TokenType.greater
            return makeToken(type: token_type, literal: nil)

        case "/":
            if match(expected: "/") {
                // comment. find newline
                while peek() != "\n" && !isAtEnd() {
                    let _ = advance()
                }
            } else {
                return makeToken(type: TokenType.slash, literal: nil)
            }
            
            
        case " ", "\t", "\r":
            break;
            
        case "\n":
            
            line += 1
            
        case "\"":
            // handle strings in a different method
            let value = stringLiteral()
            return makeToken(type: TokenType.string, literal: value)
            
            
        default:
            if c.isNumber {
                let value = numberLiteral()
                return makeToken(type: TokenType.number, literal: value)
                
            } else if c.isLetter {
                let value = identifier()
                
                if let token_type = keywords[value] {
                    // string is a keyword
                    return makeToken(type: token_type, literal: nil)
                } else {
                    // string is an identifier
                    return makeToken(type: TokenType.identifier, literal: value)
                }
            
            } else {
                Interpreter.error(line: line, message: "Unexpected character.")
            }
        }
        
        return nil
    }
    
    func advance() -> Character {
        let c = source[current]
        current += 1
        return c
    }
    
    func match(expected: Character) -> Bool {
        if isAtEnd() || source[current] != expected {
            return false
        }
        
        current += 1
        return true
    }
    
    func peek() -> Character {
        if isAtEnd() {
            return "\0"
        }
        return source[current]
    }
    
    func peekNext() -> Character {
        if current + 1 >= source.count {
            return "\0"
        } else {
            return source[current + 1]
        }
    }
    
    func sourceSubstring(start: Int, end: Int) -> String {
        let substring_start = source.index(source.startIndex, offsetBy: start)
        let substring_end = source.index(source.startIndex, offsetBy: end)
        let range = substring_start ..< substring_end
        return String(source[range])
    }
    
    func stringLiteral() -> String? {
        while peek() != "\"" && !isAtEnd() {
            if peek() == "\n" {
                line += 1
            }
            
            let _ = advance()
        }
        
        if isAtEnd() {
            Interpreter.error(line: line, message: "Unterminated string.")
            return nil
        }
        
        // closing "
        let _ = advance()
        
        return sourceSubstring(start: start + 1, end: current - 1)
    }
    
    func numberLiteral() -> Double {
        
        while peek().isNumber {
            let _ = advance()
        }
        
        // check if it's fractional
        if peek() == "." && peekNext().isNumber {
            let _ = advance()

            while peek().isNumber {
                let _ = advance()
            }
        }
        
        let number_str = sourceSubstring(start: start, end: current)
        if let value = Double(number_str) {
            return value
        } else {
            Interpreter.error(line: line, message: "Error in number parsing (this shouldn't happen!)")
            return 0;
        }
    }
    
    func identifier() -> String {
        while peek().isLetter || peek().isNumber {
            let _ = advance()
        }
        
        return sourceSubstring(start: start, end: current)
    }
    
    func makeToken(type: TokenType, literal: Any?) -> Token {
        let text = sourceSubstring(start: start, end: current)
        return Token(type: type, lexeme: text, literal: literal, line: line)
    }
}
