import Foundation

/**
 **DataSerializer**

 Serializes data to JS format and parses data coming from JS
 */
internal class DataSerializer {
    
    internal static func serialize<T>(input: T) throws -> String {
        var output: String?
        
        if let b = input as? Bool {
            output = b ? "true" : "false"
        } else if let i = input as? Int {
            output = "\(i)"
        } else if let f = input as? Float {
            output = "\(f)"
        } else if let d = input as? Double {
            output = "\(d)"
        } else if var s = input as? String {
            // As this string is going to be unwrapped from quotes, when passed to JS, all quotes need to be escaped
            s = s.stringByReplacingOccurrencesOfString("\"", withString: "\\\"", options: NSStringCompareOptions(), range: nil)
            s = s.stringByReplacingOccurrencesOfString("'", withString: "\'", options: NSStringCompareOptions(), range: nil)
            output = "\"\(s)\""
        } else if let a = input as? NSArray {
            // Array and Dictionary are serialized to JSON.
            // They should wrap only "basic" data (same types than supported ones)
            let json = try! NSJSONSerialization.dataWithJSONObject(a, options: NSJSONWritingOptions())
            output = NSString(data: json, encoding: NSUTF8StringEncoding)! as String
        } else if let d = input as? NSDictionary {
            let json = try! NSJSONSerialization.dataWithJSONObject(d, options: NSJSONWritingOptions())
            output = NSString(data: json, encoding: NSUTF8StringEncoding)! as String
        } else {
            throw CaravelError.SerializationUnsupportedData
        }
        
        return output!
    }
    
    internal static func deserialize(input: String) -> AnyObject {
        if input.characters.count > 0 {
            if (input.first == "[" && input.last == "]") || (input.first == "{" && input.last == "}") {
                // Array or Dictionary, matching JSON format
                let json = input.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
                return try! NSJSONSerialization.JSONObjectWithData(json, options: NSJSONReadingOptions())
            }
            
            if input == "true" {
                return true
            } else if input == "false" {
                return false
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