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
    private static var _singleton: UIWebViewDelegateMediator = UIWebViewDelegateMediator()
    private lazy var _webViews: [Int: [UIWebViewDelegate]] = [Int: [UIWebViewDelegate]]()
    
    private func iterateOverDelegates(webView: UIWebView, callback: (UIWebViewDelegate) -> Void) {
        var array = UIWebViewDelegateMediator._singleton._webViews[webView.hash]!
        
        for e in array {
            callback(e)
        }
    }
    
    internal static func subscribe(webView: UIWebView, subscriber: UIWebViewDelegate) {
        if webView.delegate != nil && (webView.delegate! as? UIWebViewDelegateMediator == nil)  {
            var delegates = [UIWebViewDelegate]()
            
            delegates.append(webView.delegate!)
            _singleton._webViews[webView.hash] = delegates
            
            webView.delegate = _singleton
        } else if webView.delegate == nil {
            _singleton._webViews[webView.hash] = [UIWebViewDelegate]()
            webView.delegate = _singleton
        }
        
        _singleton._webViews[webView.hash]!.append(subscriber)
    }
    
    func webView(webView: UIWebView, didFailLoadWithError error: NSError) {
        iterateOverDelegates(webView) { e in
            e.webView?(webView, didFailLoadWithError: error)
        }
    }
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        var shouldLoad = false
        
        iterateOverDelegates(webView) { e in
            var b = e.webView?(webView, shouldStartLoadWithRequest: request, navigationType: navigationType)
            
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

    
//    private var _webView: UIWebView
//    private var _firstDelegate: UIWebViewDelegate?
//    private var _secondDelegate: UIWebViewDelegate
    
//    internal init(webView: UIWebView, secondDelegate: UIWebViewDelegate) {
//        self._webView = webView
//        self._secondDelegate = secondDelegate
//        
//        super.init()
//        
//        if let d = self._webView.delegate {
//            self._firstDelegate = d
//            self._webView.delegate = self
//        } else {
//            // No delegate, mediator promotes subscriber to new delegate
//            self._webView.delegate = self._secondDelegate
//        }
//    }
    
    // Methods below are called only if there are 2+ subscribers
    // If there is only a single one, it is called directly
    
    // All calls use safe unwrapper for those method implementations are optional
    
//    func webView(webView: UIWebView, didFailLoadWithError error: NSError) {
//        _firstDelegate!.webView?(webView, didFailLoadWithError: error)
//        _secondDelegate.webView?(webView, didFailLoadWithError: error)
//    }
//    
//    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
//        var shouldLoad = true // Keep default behavior (URL needs to be run)
//        
//        if let b = _firstDelegate!.webView?(webView, shouldStartLoadWithRequest: request, navigationType: navigationType) {
//            shouldLoad = b
//        }
//        
//        _secondDelegate.webView?(webView, shouldStartLoadWithRequest: request, navigationType: navigationType)
//        
//        return shouldLoad
//    }
//    
//    func webViewDidFinishLoad(webView: UIWebView) {
//        _firstDelegate!.webViewDidFinishLoad?(webView)
//        _secondDelegate.webViewDidFinishLoad?(webView)
//    }
//    
//    func webViewDidStartLoad(webView: UIWebView) {
//        _firstDelegate!.webViewDidStartLoad?(webView)
//        _secondDelegate.webViewDidStartLoad?(webView)
//    }
}