import Foundation

/**
 * @class Subscriber
 * @brief Internal class storing bus subscribers
 */
internal class Subscriber {
    var reference: AnyObject
    var name: String
    var callback: (String, AnyObject?) -> Void
    var inBackground: Bool
    
    init(reference: AnyObject, name: String, callback: (String, AnyObject?) -> Void, inBackground: Bool) {
        self.reference = reference
        self.name = name
        self.callback = callback
        self.inBackground = inBackground
    }
}