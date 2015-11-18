import Foundation

/**
 * @class Subscriber
 * @brief Internal class storing bus subscribers
 */
internal class Subscriber {
    var name: String
    var callback: (String, AnyObject?) -> Void
    
    init(name: String, callback: (String, AnyObject?) -> Void) {
        self.name = name
        self.callback = callback
    }
}