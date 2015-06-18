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
 * @brief Serializes iOS data for JS
 */
internal class DataSerializer {
    
    internal static func run(input: AnyObject, type: SupportedType) -> String {
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
            s = s.stringByReplacingOccurrencesOfString("\"", withString: "\\\"", options: NSStringCompareOptions(), range: nil)
            s = s.stringByReplacingOccurrencesOfString("'", withString: "\'", options: NSStringCompareOptions(), range: nil)
            output = "\"\(s)\""
        case .Array, .Dictionary:
            // Array and Dictionary are serialized to JSON.
            // They should wrap only basic data (same types than supported ones)
            var json = NSJSONSerialization.dataWithJSONObject(input, options: NSJSONWritingOptions(), error: NSErrorPointer())!
            var s = NSString(data: json, encoding: NSUTF8StringEncoding)!
            output = s as String
        }
        
        return output!
    }
}