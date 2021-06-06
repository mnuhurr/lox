//
//  main.swift
//  lox
//
//  Created by Manu Harju on 5.6.2021.
//



import Foundation

func main() -> Int32 {
    var interpreter: Interpreter = Interpreter()

    if CommandLine.arguments.capacity > 2 {
        print("Usage: lox [script]")
    } else if CommandLine.arguments.capacity == 2 {
        // run file
        let file = CommandLine.arguments[1]
        
        do {
            let source = try String(contentsOfFile: file, encoding: .utf8)
            interpreter.run(source: source)
            if interpreter.hadError {
                return 65; // EX_DATAERR
            }
        } catch {
            print("Error loading file " + file)
            return 66; // EX_NOINPUT
        }
    } else {
        // run interactive
        print("> ", terminator:"")
        while let line = readLine() {
            interpreter.run(source: line)
            interpreter.hadError = false
            print("> ", terminator:"")
        }
    }
    
    return 0;
}


exit(main())
