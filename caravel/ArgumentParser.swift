//
//  ArgumentParser.swift
//  caravel
//
//  Created by Adrien on 28/05/15.
//  Copyright (c) 2015 Coshx Labs. All rights reserved.
//

import Foundation

/**
 * @class ArgumentParser
 * @brief Parses JS input to a list of arguments
 */
internal class ArgumentParser {
    
    internal class func parse(input: String) -> [String] {
        var outcome = [String]()
        var prev: Character?
        var buffer = String()
        
        if count(input) == 0 { // No arg
            return outcome
        }
        
        for current in input {
            if current == "@" {
                if prev != nil && prev != "\\" {
                    // Arguments are split using "@" symbol
                    // Existing "@" have been escaped before
                    outcome.append(buffer)
                    buffer = ""
                } else if prev != nil && prev == "\\" {
                    // Escaped "@" symbol
                    // Let's unescape it
                    var i = 0, size = count(buffer)
                    var s = ""
                    
                    for c in buffer {
                        if i < size - 1 {
                            s.append(c)
                        }
                        i++
                    }
                    
                    buffer = s
                    buffer.append(current)
                }
                // A "@" symbol cannot be first as it has been escaped, so no else condition
            } else {
                buffer.append(current)
            }
            
            prev = current
        }
        
        // Add latest buffer
        outcome.append(buffer)
        
        return outcome
    }
}