import Foundation

/**
 **ArgumentParser**

 Parses JS input to a list of arguments. Expected pattern: busName=*&eventName=*&eventData=*. Data are optional
 */
internal class ArgumentParser {
    
    internal class func parse(_ input: String) -> (busName: String, eventName: String, eventData: String?) {
        let queryPairs = input.components(separatedBy: "&")
        var outcome: (busName: String, eventName: String, eventData: String?) = (busName: "", eventName: "", eventData: nil)
        
        for p in queryPairs {
            var keyValue = p.components(separatedBy: "=")
            if keyValue[0] == "busName" {
                outcome.busName = keyValue[1].removingPercentEncoding!
            } else if keyValue[0] == "eventName" {
                outcome.eventName = keyValue[1].removingPercentEncoding!
            } else if keyValue[0] == "eventData" {
                outcome.eventData = keyValue[1].removingPercentEncoding
            }
        }
        
        return outcome
    }
}
