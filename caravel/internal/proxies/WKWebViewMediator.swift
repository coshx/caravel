import WebKit

internal class WKScriptMessageHandlerProxyMediator {
    private static let creationLock = NSObject()
    
    private static var proxies: [Int: WKScriptMessageHandlerProxy] = [:]
    
    private static func lockProxies(@noescape action: () -> Void) {
        synchronized(creationLock, action: action)
    }
    
    static func subscribe(configuration: WKWebViewConfiguration, observer: IWKWebViewObserver) {
        let action: Void -> Bool  = {
            for (k, v) in proxies {
                if k == configuration.hash {
                    v.subscribe(observer)
                    return true
                }
            }
            return false
        }
        
        if !action() {
            lockProxies {
                if action() {
                    return
                } else {
                    let p = WKScriptMessageHandlerProxy(configuration: configuration)
                    p.subscribe(observer)
                    proxies[configuration.hash] = p
                }
            }
        }
    }
    
    static func unsubscribe(configuration: WKWebViewConfiguration, observer: IWKWebViewObserver) {
        for (k, v) in proxies {
            if k == configuration.hash {
                v.unsubscribe(observer)
                
                if !v.hasSubscribers() {
                    lockProxies {
                        proxies.removeValueForKey(configuration.hash)
                    }
                }
                return
            }
        }
    }
}