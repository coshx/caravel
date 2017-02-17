import UIKit

/**
 **UIWebViewDelegateProxyMediator**

 Manages any UIWebViewDelegateProxy instance. One per UIWebView
 */
internal class UIWebViewDelegateProxyMediator {
    fileprivate static let creationLock = NSObject()

    /**
     Indexed by UIWebViews' hash
     */
    fileprivate static var proxies: [Int: UIWebViewDelegateProxy] = [:]

    fileprivate static func lockProxies(_ action: () -> Void) {
        synchronized(creationLock, action: action)
    }

    static func subscribe(_ webView: UIWebView, observer: IUIWebViewObserver) {
        let action: (Void) -> Bool = {
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

    static func unsubscribe(_ webView: UIWebView, observer: IUIWebViewObserver) {
        for (k, v) in proxies {
            if k == webView.hash {
                v.unsubscribe(observer)

                if !v.hasSubscribers() {
                    v.deactivate(webView)
                    lockProxies {
                        proxies.removeValue(forKey: webView.hash)
                    }
                }
                return
            }
        }
    }
}
