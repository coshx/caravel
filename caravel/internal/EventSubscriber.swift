/**
 **EventSubscriber**

 Internal class storing bus subscribers
 */
internal class EventSubscriber {
    var name: String
    var callback: (String, AnyObject?) -> Void
    var inBackground: Bool
    
    init(name: String, callback: (String, AnyObject?) -> Void, inBackground: Bool) {
        self.name = name
        self.callback = callback
        self.inBackground = inBackground
    }
}