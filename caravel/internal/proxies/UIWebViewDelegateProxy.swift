import UIKit

/**
 **UIWebViewDelegateProxy**

 Saves current webview delegate (if any) and dispatches events to subscribers
 */
internal class UIWebViewDelegateProxy: NSObject, UIWebViewDelegate {
    fileprivate static let subscriberLock = NSObject()
    
    fileprivate var originalDelegate: UIWebViewDelegate?
    
    /**
     All the subscribers
     */
    fileprivate lazy var subscribers: [IUIWebViewObserver] = []
    
    init(webView: UIWebView) {
        self.originalDelegate = webView.delegate
        
        super.init()
        
        webView.delegate = self
    }
    
    fileprivate func lockSubscribers(_ action: () -> Void) {
        synchronized(UIWebViewDelegateProxy.subscriberLock, action: action)
    }
    
    fileprivate func iterateOverDelegates(_ callback: (IUIWebViewObserver) -> Void) {
        self.lockSubscribers {
            for e in self.subscribers {
                callback(e)
            }
        }
    }
    
    func subscribe(_ subscriber: IUIWebViewObserver) {
        lockSubscribers {
            for s in self.subscribers {
                if s.hash == subscriber.hash {
                    return
                }
            }
            
            self.subscribers.append(subscriber)
        }
    }
    
    func unsubscribe(_ subscriber: IUIWebViewObserver) {
        lockSubscribers {
            var i = 0
            for e in self.subscribers {
                if e.hash == subscriber.hash {
                    self.subscribers.remove(at: i)
                    return
                }
                i += 1
            }
        }
    }
    
    func hasSubscribers() -> Bool {
        return self.subscribers.count > 0
    }
    
    func deactivate(_ webView: UIWebView) {
        webView.delegate = self.originalDelegate
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        self.originalDelegate?.webView?(webView, didFailLoadWithError: error)
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        var shouldLoad = true // Default behavior: execute URL
        let original = self.originalDelegate?.webView?(webView, shouldStartLoadWith: request, navigationType: navigationType)
        
        if let b = original {
            shouldLoad = shouldLoad && b
        }
        
        if let scheme: String = request.url?.scheme {
            if scheme == "caravel" {
                let args = ArgumentParser.parse(request.url!.query!)
                
                iterateOverDelegates {e in
                    e.onMessage(args.busName, eventName: args.eventName, rawEventData: args.eventData)
                }
                
                shouldLoad = false
            }
        }
        
        return shouldLoad
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        self.originalDelegate?.webViewDidFinishLoad?(webView)
    }
    
    func webViewDidStartLoad(_ webView: UIWebView) {
        self.originalDelegate?.webViewDidStartLoad?(webView)
    }
}
