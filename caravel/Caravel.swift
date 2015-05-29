//
//  Bus.swift
//  todolist
//
//  Created by Adrien on 23/05/15.
//  Copyright (c) 2015 test. All rights reserved.
//

import Foundation
import UIKit

/**
  * @class Caravel
  * @brief Main class of the library. The only public one.
  * Manages all buses and dispatches actions to other components.
  */
public class Caravel: NSObject, UIWebViewDelegate {
    
    /**
     * Default Bus
     */
    private static var _default: Caravel?
    private static var _buses: [Caravel] = [Caravel]()
    
    private var _name: String
    
    /**
     * Bus subscribers
     */
    private lazy var _subscribers: [Subscriber] = [Subscriber]()
    
    
    /**
    * Tells if bus has received the init event from JS
    */
    private var _isInitialized: Bool
    private static var _initializationLock = NSObject()
    
    /**
     * Pending initialization subscribers
     */
    private lazy var _initializers: [(Caravel) -> Void] = Array<(Caravel) -> Void>()
    
    private var _webView: UIWebView
    
    private init(name: String, webView: UIWebView) {
        self._name = name
        self._isInitialized = false
        self._webView = webView
        
        super.init()
        
        UIWebViewDelegateMediator(webView: self._webView, secondDelegate: self)
    }

    /**
     * Sends event to JS
     */
    private func _post(eventName: String, eventData: AnyObject?, type: SupportedType?) {
        var toRun: String?
        var data: String?
        
        if let d: AnyObject = eventData {
            data = DataSerializer.run(d, type: type!)
        } else {
            data = "null"
        }
        
        if _name == "default" {
            toRun = "Caravel.getDefault().raise(\"\(eventName)\", \(data!))"
        } else {
            toRun = "Caravel.get(\"\(_name)\").raise(\"\(eventName)\", \(data!))"
        }
        
        self._webView.stringByEvaluatingJavaScriptFromString(toRun!)
    }
    
    public var name: String {
        return _name
    }
    
    /**
     * Caravel expects the following pattern:
     * caravel@bus_name@event_name@extra_arg
     *
     * Followed argument types are supported:
     * int, float, double, string
     */
    public func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if let lastPathComponent: String = request.URL?.lastPathComponent {
            
            // The last path of the URL needs to contains at least the "caravel" word
            if count(lastPathComponent) > count("caravel") && (lastPathComponent as NSString).substringToIndex(count("caravel")) == "caravel" {
                var args = ArgumentParser.parse(lastPathComponent)
                var busName = args[1]
                var eventName = args[2]
                
                // All buses are notified about that incoming event. Then, they need to investigate first if they
                // are potential receivers
                if _name == busName {
                    if eventName == "CaravelInit" { // Reserved event name. Triggers whenReady
                        objc_sync_enter(Caravel._initializationLock)
                        _isInitialized = true
                        
                        for i in _initializers {
                            dispatch_async(dispatch_get_main_queue()) {
                                i(self)
                            }
                        }
                        
                        objc_sync_exit(Caravel._initializationLock)
                    } else {
                        var eventData: AnyObject? = nil
                        
                        if args.count > 3 { // Arg is optional
                            eventData = args[3]
                        }
                        
                        for s in _subscribers {
                            if s.name == eventName {
                                dispatch_async(dispatch_get_main_queue()) {
                                    s.callback(eventName, eventData)
                                }
                            }
                        }
                    }
                }
                
                // As it is a custom URL, we need to prevent the webview to run it
                return false
            }
            
            return true
        }
        
        return true
    }
    
    /**
     * Returns the current bus when its JS counterpart is ready
     */
    public func whenReady(callback: (Caravel) -> Void) {
        objc_sync_enter(Caravel._initializationLock)
        if _isInitialized {
            objc_sync_exit(Caravel._initializationLock) // Release lock before running callback, to avoid delays
            callback(self)
        } else {
            _initializers.append(callback)
            objc_sync_exit(Caravel._initializationLock)
        }
    }
    
    /**
     * Posts event without any argument
     */
    public func post(eventName: String) {
        _post(eventName, eventData: nil, type: nil)
    }
    
    /**
    * Posts event with an extra int
    */
    public func post(eventName: String, anInt: Int) {
        _post(eventName, eventData: anInt, type: .Int)
    }
    
    /**
    * Posts event with an extra bool
    */
    public func post(eventName: String, aBool: Bool) {
        _post(eventName, eventData: aBool, type: .Bool)
    }
    
    /**
    * Posts event with an extra double
    */
    public func post(eventName: String, aDouble: Double) {
        _post(eventName, eventData: aDouble, type: .Double)
    }
    
    /**
    * Posts event with an extra float
    */
    public func post(eventName: String, aFloat: Float) {
        _post(eventName, eventData: aFloat, type: .Double)
    }
    
    /**
    * Posts event with an extra array
    */
    public func post(eventName: String, anArray: NSArray) {
        _post(eventName, eventData: anArray, type: .Array)
    }
    
    /**
    * Posts event with an extra dictionary
    */
    public func post(eventName: String, aDictionary: NSDictionary) {
        _post(eventName, eventData: aDictionary, type: .Dictionary)
    }
    
    /**
     * Subscribes to provided event. Callback is run with the event's name and extra data
     */
    public func register(eventName: String, callback: (String, AnyObject?) -> Void) {
        _subscribers.append(Subscriber(name: eventName, callback: callback))
    }
    
    /**
     * Returns the default bus
     */
    public static func getDefault(webView: UIWebView) -> Caravel {
        if let d = _default {
            return d
        } else {
            _default = Caravel(name: "default", webView: webView)
            return _default!
        }
    }
    
    /**
     * Returns custom bus
     */
    public static func get(name: String, webView: UIWebView) -> Caravel {
        if name == "default" {
            return getDefault(webView)
        } else {
            var newBus: Caravel?
            
            for b in _buses {
                if b.name == name {
                    return b
                }
            }
            
            newBus = Caravel(name: name, webView: webView)
            _buses.append(newBus!)
            return newBus!
        }
    }
}