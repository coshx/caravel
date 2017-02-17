import WebKit

/**
 **WKScriptMessageHandlerProxyMediator**

 Manages any WKScriptMessageHandlerProxy instance. One per WKWebViewConfiguration.
 */
internal class WKScriptMessageHandlerProxyMediator {
    fileprivate static let creationLock = NSObject()

    /**
     Indexed by WKWebViewConfiguration's hash
     */
    fileprivate static var proxies: [Int: WKScriptMessageHandlerProxy] = [:]

    fileprivate static func lockProxies(_ action: () -> Void) {
        synchronized(creationLock, action: action)
    }

    static func subscribe(_ configuration: WKWebViewConfiguration, observer: IWKWebViewObserver) {
        let key = configuration.hash

        if let p = proxies[key] {
            p.subscribe(observer)
        } else {
            lockProxies {
                if let p = proxies[key] {
                    p.subscribe(observer)
                } else {
                    let proxy = WKScriptMessageHandlerProxy(configuration: configuration)
                    proxy.subscribe(observer)
                    proxies[key] = proxy
                }
            }
        }
    }

    static func unsubscribe(_ configuration: WKWebViewConfiguration, observer: IWKWebViewObserver) {
        let key = configuration.hash

        if let p = proxies[key] {
            p.unsubscribe(observer)

            if !p.hasSubscribers() {
                lockProxies {
                    if !p.hasSubscribers() {
                        p.willBeDeleted(configuration)
                        proxies.removeValue(forKey: key)
                    }
                }
            }
        }
    }
}
