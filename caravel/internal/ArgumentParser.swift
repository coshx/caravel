import Foundation

/**
 **ArgumentParser**

 Parses JS input to a list of arguments. Expected pattern: busName=*&eventName=*&eventData=*. Data are optional
 */
internal class ArgumentParser {
    
    internal class func parse(input: String) -> (busName: String, eventName: String, eventData: String?) {
        let queryPairs = input.componentsSeparatedByString("&")
        var outcome: (busName: String, eventName: String, eventData: String?) = (busName: "", eventName: "", eventData: nil)
        
        for p in queryPairs {
            var keyValue = p.componentsSeparatedByString("=")
            if keyValue[0] == "busName" {
                outcome.busName = keyValue[1].stringByRemovingPercentEncoding!
            } else if keyValue[0] == "eventName" {
                outcome.eventName = keyValue[1].stringByRemovingPercentEncoding!
            } else if keyValue[0] == "eventData" {
                outcome.eventData = keyValue[1].stringByRemovingPercentEncoding
            }
        }
        
        return outcome
    }
}