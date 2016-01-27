import UIKit

/**
 **UIWebViewDelegateProxyMediator**

 Manages any UIWebViewDelegateProxy instance. One per UIWebView
 */
internal class UIWebViewDelegateProxyMediator {
    private static let creationLock = NSObject()

    /**
     Indexed by UIWebViews' hash
     */
    private static var proxies: [Int: UIWebViewDelegateProxy] = [:]

    private static func lockProxies(@noescape action: () -> Void) {
        synchronized(creationLock, action: action)
    }

    static func subscribe(webView: UIWebView, observer: IUIWebViewObserver) {
        let action: Void -> Bool = {
            for (k, v) in proxies {
                if k == webView.hash {
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
                    let p = UIWebViewDelegateProxy(webView: webView)
                    p.subscribe(observer)
                    proxies[webView.hash] = p
                }
            }
        }
    }

    static func unsubscribe(webView: UIWebView, observer: IUIWebViewObserver) {
        for (k, v) in proxies {
            if k == webView.hash {
                v.unsubscribe(observer)

                if !v.hasSubscribers() {
                    v.deactivate(webView)
                    lockProxies {
                        proxies.removeValueForKey(webView.hash)
                    }
                }
                return
            }
        }
    }
}