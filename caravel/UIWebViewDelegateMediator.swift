//
//  UIWebViewDelegateMediator.swift
//  todolist
//
//  Created by Adrien on 24/05/15.
//  Copyright (c) 2015 test. All rights reserved.
//

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
    private static var _singleton: UIWebViewDelegateMediator = UIWebViewDelegateMediator()
    
    /**
     * All the subscribers. They are sorted by webview's hash
     */
    private lazy var _webViewSubscribers: [Int: [UIWebViewDelegate]] = [Int: [UIWebViewDelegate]]()
    
    private func iterateOverDelegates(webView: UIWebView, callback: (UIWebViewDelegate) -> Void) {
        var array = UIWebViewDelegateMediator._singleton._webViewSubscribers[webView.hash]!
        
        for e in array {
            callback(e)
        }
    }
    
    internal static func subscribe(webView: UIWebView, subscriber: UIWebViewDelegate) {
        if webView.delegate != nil && (webView.delegate! as? UIWebViewDelegateMediator == nil)  {
            // There is already a delegate, save it before overwriting it
            var delegates = [UIWebViewDelegate]()
            
            delegates.append(webView.delegate!)
            _singleton._webViewSubscribers[webView.hash] = delegates
            
            webView.delegate = _singleton
        } else if webView.delegate == nil {
            // No delegate, just initialize
            _singleton._webViewSubscribers[webView.hash] = [UIWebViewDelegate]()
            webView.delegate = _singleton
        }
        
        _singleton._webViewSubscribers[webView.hash]!.append(subscriber)
    }
    
    // About methods below:
    // All calls use safe unwrapper for those method implementations are optional
    
    func webView(webView: UIWebView, didFailLoadWithError error: NSError) {
        iterateOverDelegates(webView) { e in
            e.webView?(webView, didFailLoadWithError: error)
        }
    }
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        var shouldLoad = false // Default behavior: do not execute URL
        // If any subscriber woud like t
        
        iterateOverDelegates(webView) { e in
            var b = e.webView?(webView, shouldStartLoadWithRequest: request, navigationType: navigationType)
            
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