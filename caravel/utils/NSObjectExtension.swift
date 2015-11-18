internal extension NSObject {
    static func synchronized(lock: AnyObject, action: () -> Void) {
        objc_sync_enter(lock)
        action()
        objc_sync_exit(lock)
    }
    
    func synchronized(lock: AnyObject, action: () -> Void) {
        NSObject.synchronized(lock, action: action)
    }
}