internal class ThreadingHelper {
    static func main(action: () -> Void) {
        dispatch_async(dispatch_get_main_queue()) { action() }
    }
    
    static func background(action: () -> Void) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            action()
        }
    }
}