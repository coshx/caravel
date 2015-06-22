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
            var b = input as! Bool
            output = b ? "true" : "false"
        case .Int:
            var i = input as! Int
            output = "\(i)"
        case .Double:
            var d = input as! Double
            output = "\(d)"
        case .Float:
            var f = input as! Float
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
            var json = NSJSONSerialization.dataWithJSONObject(input, options: NSJSONWritingOptions(), error: NSErrorPointer())!
            var s = NSString(data: json, encoding: NSUTF8StringEncoding)!
            output = s as String
        }
        
        return output!
    }
    
    internal static func deserialize(input: String) -> AnyObject {
        if count(input) > 0 {
            if input[0] == "[" || input[0] == "{" { // Array or Dictionary, matching JSON format
                var json = input.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
                return NSJSONSerialization.JSONObjectWithData(json, options: NSJSONReadingOptions(), error: NSErrorPointer())!
            }
            
            // To investigate if the input is a number (int or double),
            // we check if the first char is a digit or no
            if let isANumber = input[0].toInt() {
                if let i = input.toInt() {
                    return i
                } else {
                    return (input as NSString).doubleValue
                }
            }
        }
        
        return input
    }
}