//
//  UIWebViewDelegateMediator.swift
//  todolist
//
//  Created by Adrien on 24/05/15.
//  Copyright (c) 2015 test. All rights reserved.
//

import Foundation
import UIKit

internal class UIWebViewDelegateMediator: NSObject, UIWebViewDelegate {
    private var _webView: UIWebView
    private var _firstDelegate: UIWebViewDelegate?
    private var _secondDelegate: UIWebViewDelegate
    
    internal init(webView: UIWebView, secondDelegate: UIWebViewDelegate) {
        self._webView = webView
        self._secondDelegate = secondDelegate
        
        super.init()
        
        if let d = self._webView.delegate {
            self._firstDelegate = d
            self._webView.delegate = self
        } else {
            self._webView.delegate = self._secondDelegate
        }
    }
    
    func webView(webView: UIWebView, didFailLoadWithError error: NSError) {
        _firstDelegate!.webView?(webView, didFailLoadWithError: error)
        _secondDelegate.webView?(webView, didFailLoadWithError: error)
    }
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        _secondDelegate.webView!(webView, shouldStartLoadWithRequest: request, navigationType: navigationType)
        
        // If those lines are run, first delegate exists
        return _firstDelegate!.webView!(webView, shouldStartLoadWithRequest: request, navigationType: navigationType)
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        _firstDelegate!.webViewDidFinishLoad?(webView)
        _secondDelegate.webViewDidFinishLoad?(webView)
    }
    
    func webViewDidStartLoad(webView: UIWebView) {
        _firstDelegate!.webViewDidStartLoad?(webView)
        _secondDelegate.webViewDidStartLoad?(webView)
    }
}