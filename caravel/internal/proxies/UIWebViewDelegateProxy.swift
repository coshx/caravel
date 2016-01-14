import UIKit

/**
 **UIWebViewDelegateProxy**

 Saves current webview delegate (if any) and dispatches events to subscribers
 */
internal class UIWebViewDelegateProxy: NSObject, UIWebViewDelegate {
    private static let subscriberLock = NSObject()
    
    private var originalDelegate: UIWebViewDelegate?
    
    /**
     All the subscribers
     */
    private lazy var subscribers: [IUIWebViewObserver] = []
    
    init(webView: UIWebView) {
        self.originalDelegate = webView.delegate
        
        super.init()
        
        webView.delegate = self
    }
    
    private func lockSubscribers(@noescape action: () -> Void) {
        synchronized(UIWebViewDelegateProxy.subscriberLock, action: action)
    }
    
    private func iterateOverDelegates(callback: (IUIWebViewObserver) -> Void) {
        self.lockSubscribers {
            for e in self.subscribers {
                callback(e)
            }
        }
    }
    
    func subscribe(subscriber: IUIWebViewObserver) {
        lockSubscribers {
            for s in self.subscribers {
                if s.hash == subscriber.hash {
                    return
                }
            }
            
            self.subscribers.append(subscriber)
        }
    }
    
    func unsubscribe(subscriber: IUIWebViewObserver) {
        lockSubscribers {
            var i = 0
            for e in self.subscribers {
                if e.hash == subscriber.hash {
                    self.subscribers.removeAtIndex(i)
                    return
                }
                i++
            }
        }
    }
    
    func hasSubscribers() -> Bool {
        return self.subscribers.count > 0
    }
    
    func deactivate(webView: UIWebView) {
        webView.delegate = self.originalDelegate
    }
    
    func webView(webView: UIWebView, didFailLoadWithError error: NSError?) {
        self.originalDelegate?.webView?(webView, didFailLoadWithError: error)
    }
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        var shouldLoad = true // Default behavior: execute URL
        let original = self.originalDelegate?.webView?(webView, shouldStartLoadWithRequest: request, navigationType: navigationType)
        
        if let b = original {
            shouldLoad = shouldLoad && b
        }
        
        if let scheme: String = request.URL?.scheme {
            if scheme == "caravel" {
                let args = ArgumentParser.parse(request.URL!.query!)
                
                iterateOverDelegates {e in
                    e.onMessage(args.busName, eventName: args.eventName, rawEventData: args.eventData)
                }
                
                shouldLoad = false
            }
        }
        
        return shouldLoad
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        self.originalDelegate?.webViewDidFinishLoad?(webView)
    }
    
    func webViewDidStartLoad(webView: UIWebView) {
        self.originalDelegate?.webViewDidStartLoad?(webView)
    }
}