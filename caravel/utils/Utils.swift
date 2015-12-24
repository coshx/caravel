internal func synchronized(lock: AnyObject, @noescape action: () -> Void) {
    objc_sync_enter(lock)
    action()
    objc_sync_exit(lock)
}

internal func main(action: () -> Void) {
    dispatch_async(dispatch_get_main_queue()) { action() }
}
    
internal func background(action: () -> Void) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
        action()
    }
}