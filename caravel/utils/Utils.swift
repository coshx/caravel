internal func synchronized(_ lock: AnyObject, action: () -> Void) {
    objc_sync_enter(lock)
    action()
    objc_sync_exit(lock)
}

internal func main(_ action: @escaping () -> Void) {
    DispatchQueue.main.async { action() }
}
    
internal func background(_ action: @escaping () -> Void) {
    DispatchQueue.global(qos: .default).async {
        action()
    }
}
