//
//  CaravelSerializer.swift
//  caravel
//
//  Created by Adrien on 28/05/15.
//  Copyright (c) 2015 Coshx Labs. All rights reserved.
//

import Foundation

/**
 * @class DataSerializer
 * @brief Serializes data to JS format and parses data coming from JS
 */
internal class DataSerializer {
    
    internal static func serialize(input: AnyObject, type: SupportedType) -> String {
        var output: String?
        
        switch (type) {
        case .Bool:
            let b = input as! Bool
            output = b ? "true" : "false"
        case .Int:
            let i = input as! Int
            output = "\(i)"
        case .Double:
            let d = input as! Double
            output = "\(d)"
        case .Float:
            let f = input as! Float
            output = "\(f)"
        case .String:
            var s = input as! String
            // As string is going to be unwrapped from quotes, when passed to JS, all quotes need to be escaped
            s = s.stringByReplacingOccurrencesOfString("\"", withString: "\\\"", options: NSStringCompareOptions(), range: nil)
            s = s.stringByReplacingOccurrencesOfString("'", withString: "\'", options: NSStringCompareOptions(), range: nil)
            output = "\"\(s)\""
        case .Array, .Dictionary:
            // Array and Dictionary are serialized to JSON.
            // They should wrap only "basic" data (same types than supported ones)
            let json = try! NSJSONSerialization.dataWithJSONObject(input, options: NSJSONWritingOptions())
            let s = NSString(data: json, encoding: NSUTF8StringEncoding)!
            output = s as String
        }
        
        return output!
    }
    
    internal static func deserialize(input: String) -> AnyObject {
        if input.characters.count > 0 {
            if input[0] == "[" || input[0] == "{" { // Array or Dictionary, matching JSON format
                let json = input.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
                return try! NSJSONSerialization.JSONObjectWithData(json, options: NSJSONReadingOptions())
            }
            
            var isNumber = true
            for i in 0..<input.characters.count {
                if Int(input[i]) != nil || input[i] == "." || input[i] == "," {
                   // Do nothing
                } else {
                    isNumber = false
                    break
                }
            }
            
            if isNumber {
                if let i = Int(input) {
                    return i
                } else {
                    return (input as NSString).doubleValue
                }
            }
        }
        
        return input
    }
}