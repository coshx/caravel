internal class CaravelFactory {
    private static let defaultBusLock = NSObject()
    private static var defaultBus: Caravel?
    
    private static let creationLock = NSObject()
    private static var busLocks: [String: NSObject] = [:]
    private static var buses: [String: Caravel] = [:]
    
    private static func getLock(name: String) -> NSObject {
        if let o = busLocks[name] {
            return o
        } else {
            objc_sync_enter(creationLock)
            if let o = busLocks[name] {
                objc_sync_exit(creationLock)
                return o
            } else {
                let o = NSObject()
                busLocks[name] = o
                objc_sync_exit(creationLock)
                return o
            }
        }
    }
    
    internal static func getDefault(webView: UIWebView) -> Caravel {
        let getExisting = { () -> Caravel? in
            if let b = defaultBus {
                b.setWebView(webView)
                return b
            } else {
                return nil
            }
        }
        
        if let bus = getExisting() {
            return bus
        } else {
            // setWebView must be run within a synchronized block
            objc_sync_enter(defaultBusLock)
            if let bus = getExisting() { // bus has been created while waiting
                objc_sync_exit(defaultBusLock)
                return bus
            } else {
                self.defaultBus = Caravel(name: Caravel.DEFAULT_BUS_NAME, webView: webView)
                objc_sync_exit(defaultBusLock)
                return self.defaultBus!
            }
        }
    }
    
    internal static func get(name: String, webView: UIWebView) -> Caravel {
        if name == Caravel.DEFAULT_BUS_NAME {
            return getDefault(webView)
        } else {
            let getExisting = { () -> Caravel? in
                if let b = buses[name] {
                    b.setWebView(webView)
                    return b
                } else {
                    return nil
                }
            }
            
            if let bus = getExisting() {
                return bus
            } else {
                // setWebView must be run within a synchronized block
                objc_sync_enter(getLock(name))
                if let bus = getExisting() {
                    objc_sync_exit(getLock(name))
                    return bus
                } else {
                    let newBus = Caravel(name: name, webView: webView)
                    self.buses[name] = newBus
                    objc_sync_exit(getLock(name))
                    return newBus
                }
            }
        }
    }
}