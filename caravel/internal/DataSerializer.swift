import Foundation

/**
 **DataSerializer**

 Serializes data to JS format and parses data coming from JS
 */
internal class DataSerializer {
    
    internal static func serialize<T>(_ input: T) throws -> String {
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
            s = s.replacingOccurrences(of: "\"", with: "\\\"", options: NSString.CompareOptions(), range: nil)
            s = s.replacingOccurrences(of: "'", with: "\'", options: NSString.CompareOptions(), range: nil)
            output = "\"\(s)\""
        } else if let a = input as? NSArray {
            // Array and Dictionary are serialized to JSON.
            // They should wrap only "basic" data (same types than supported ones)
            let json = try! JSONSerialization.data(withJSONObject: a, options: JSONSerialization.WritingOptions())
            output = NSString(data: json, encoding: String.Encoding.utf8.rawValue)! as String
        } else if let d = input as? NSDictionary {
            let json = try! JSONSerialization.data(withJSONObject: d, options: JSONSerialization.WritingOptions())
            output = NSString(data: json, encoding: String.Encoding.utf8.rawValue)! as String
        } else {
            throw CaravelError.serializationUnsupportedData
        }
        
        return output!
    }
    
    internal static func deserialize(_ input: String) -> AnyObject {
        if input.characters.count > 0 {
            if (input.first == "[" && input.last == "]") || (input.first == "{" && input.last == "}") {
                // Array or Dictionary, matching JSON format
                let json = input.data(using: String.Encoding.utf8, allowLossyConversion: false)!
                return try! JSONSerialization.jsonObject(with: json, options: JSONSerialization.ReadingOptions()) as AnyObject
            }
            
            if input == "true" {
                return true as AnyObject
            } else if input == "false" {
                return false as AnyObject
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
                    return i as AnyObject
                } else {
                    return (input as NSString).doubleValue as AnyObject
                }
            }
        }
        
        return input as AnyObject
    }
}
