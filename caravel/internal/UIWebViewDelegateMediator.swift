import Foundation
import UIKit

/**
 * @class UIWebViewDelegateMediator
 * @brief Saves current webview delegate (if existing) and dispatches events to subscribers
 */
internal class UIWebViewDelegateMediator: NSObject, UIWebViewDelegate {
    /**
     * This mediator is singleton for only a single delegate is allowed
     */
    private static var singleton: UIWebViewDelegateMediator = UIWebViewDelegateMediator()
    
    /**
     * All the subscribers. They are grouped by webview's hash
     */
    private lazy var webViewSubscribers: [Int: [UIWebViewDelegate]] = [:]
    
    private override init() { super.init() }
    
    private func iterateOverDelegates(webView: UIWebView, callback: (UIWebViewDelegate) -> Void) {
        let array = UIWebViewDelegateMediator.singleton.webViewSubscribers[webView.hash]!
        
        for e in array {
            callback(e)
        }
    }
    
    internal static func subscribe(webView: UIWebView, subscriber: UIWebViewDelegate) {
        if webView.delegate != nil && (webView.delegate! as? UIWebViewDelegateMediator == nil)  {
            // There is already a delegate, save it before overwriting it
            var delegates = [UIWebViewDelegate]()
            
            delegates.append(webView.delegate!)
            singleton.webViewSubscribers[webView.hash] = delegates
            
            webView.delegate = singleton
        } else if webView.delegate == nil {
            // No delegate, just initialize
            singleton.webViewSubscribers[webView.hash] = [UIWebViewDelegate]()
            webView.delegate = singleton
        }
        
        singleton.webViewSubscribers[webView.hash]!.append(subscriber)
    }
    
    internal static func unsubscribe(webView: UIWebView, subscriber: UIWebViewDelegate) {
        for (key, delegates) in singleton.webViewSubscribers {
            if key == webView.hash {
                var i = 0
                for d in delegates {
                    if d.hash == subscriber.hash {
                        var a = singleton.webViewSubscribers[key]!
                        a.removeAtIndex(i)
                        if a.count == 0 {
                            singleton.webViewSubscribers.removeValueForKey(key)
                        }
                        return
                    }
                    i++
                }
            }
        }
    }
    
    // About methods below:
    // All calls use safe unwrapper for those method implementations are optional
    
    func webView(webView: UIWebView, didFailLoadWithError error: NSError?) {
        iterateOverDelegates(webView) { e in
            e.webView?(webView, didFailLoadWithError: error)
        }
    }
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        var shouldLoad = false // Default behavior: do not execute URL
        // If any subscriber woud like t
        
        iterateOverDelegates(webView) { e in
            let b = e.webView?(webView, shouldStartLoadWithRequest: request, navigationType: navigationType)
            
            // If any subscriber would like to run that URL, DO NOT prevent it to do it
            shouldLoad = (b == nil) ? shouldLoad : (shouldLoad || b!)
        }
        
        return shouldLoad
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        iterateOverDelegates(webView) { e in
            e.webViewDidFinishLoad?(webView)
        }
    }
    
    func webViewDidStartLoad(webView: UIWebView) {
        iterateOverDelegates(webView) { e in
            e.webViewDidStartLoad?(webView)
        }
    }
}