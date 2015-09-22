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
    private static let DEFAULT_BUS_NAME = "default"
    
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
     * Denotes if the bus has received the init event from JS
     */
    private var _isInitialized: Bool
    
    // Multithreading locks
    private static var _defaultInitLock = NSObject()
    private static var _namedBusInitLock = NSObject()
    
    /**
     * Pending initialization subscribers
     */
    private lazy var _initializers: [(Caravel) -> Void] = []
    // Initializers are temporary saved in order to prevent them to be garbage
    // collected
    private lazy var _onGoingInitializers: [Int: ((Caravel) -> Void)] = [:]
    private lazy var _onGoingInitializersId = 0
    
    private var _webView: UIWebView
    
    private init(name: String, webView: UIWebView) {
        self._name = name
        self._isInitialized = false
        self._webView = webView
        
        super.init()
        
        UIWebViewDelegateMediator.subscribe(self._webView, subscriber: self)
    }

    /**
     * Sends event to JS
     */
    private func _post(eventName: String, eventData: AnyObject?, type: SupportedType?) {
        var toRun: String?
        var data: String?
        
        if let d: AnyObject = eventData {
            data = DataSerializer.serialize(d, type: type!)
        } else {
            data = "null"
        }
        
        if _name == "default" {
            toRun = "Caravel.getDefault().raise(\"\(eventName)\", \(data!))"
        } else {
            toRun = "Caravel.get(\"\(_name)\").raise(\"\(eventName)\", \(data!))"
        }
        
        dispatch_async(dispatch_get_main_queue()) {
            self._webView.stringByEvaluatingJavaScriptFromString(toRun!)            
        }
    }
    
    /**
     * If the controller is resumed, the webView may have changed.
     * Caravel has to watch this new component again
     */
    internal func setWebView(webView: UIWebView) {
        if webView.hash == _webView.hash {
            return
        }
        // whenReady() should be triggered only after a CaravelInit event
        // has been raised (aka wait for JS before calling whenReady)
        _isInitialized = false
        _webView = webView
        UIWebViewDelegateMediator.subscribe(_webView, subscriber: self)
    }
    
    internal func synchronized(action: () -> Void) {
        let lock = (_name == Caravel.DEFAULT_BUS_NAME) ? Caravel._defaultInitLock : Caravel._namedBusInitLock
        
        objc_sync_enter(lock)
        action()
        objc_sync_exit(lock)
    }
    
    public var name: String {
        return _name
    }
    
    /**
     * Caravel expects the following pattern:
     * caravel://host.com?busName=*&eventName=*&eventData=*
     *
     * Followed argument types are supported:
     * int, float, double, string
     */
    public func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if let scheme: String = request.URL?.scheme {
            if scheme == "caravel" {
                let args = ArgumentParser.parse(request.URL!.query!)
                
                // All buses are notified about that incoming event. Then, they need to investigate first if they
                // are potential receivers
                if _name == args.busName {
                    if args.eventName == "CaravelInit" { // Reserved event name. Triggers whenReady
                        if !_isInitialized {
                            synchronized() {
                                if !self._isInitialized {
                                    self._isInitialized = true
                                
                                    for i in self._initializers {
                                        let index = self._onGoingInitializersId
                                        
                                        self._onGoingInitializers[index] = i
                                        self._onGoingInitializersId++
                                        
                                        dispatch_async(dispatch_get_main_queue()) {
                                            i(self)
                                            self._onGoingInitializers.removeValueForKey(index)
                                        }
                                    }
                                    self._initializers = Array<(Caravel) -> Void>()
                                }
                            }
                        }
                    } else {
                        var eventData: AnyObject? = nil
                        
                        if let d = args.eventData { // Data are optional
                            eventData = DataSerializer.deserialize(d)
                        }
                        
                        for s in _subscribers {
                            if s.name == args.eventName {
                                dispatch_async(dispatch_get_main_queue()) {
                                    s.callback(args.eventName, eventData)
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
        if _isInitialized {
            dispatch_async(dispatch_get_main_queue()) {
                callback(self)
            }
        } else {
            synchronized() {
                if self._isInitialized {
                    dispatch_async(dispatch_get_main_queue()) {
                        callback(self)
                    }
                } else {
                    self._initializers.append(callback)
                }
            }
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
        _post(eventName, eventData: aFloat, type: .Float)
    }
    
    /**
    * Posts event with an extra string
    */
    public func post(eventName: String, aString: String) {
        _post(eventName, eventData: aString, type: .String)
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
        let getExisting = { () -> Caravel? in
            if let b = Caravel._default {
                b.setWebView(webView)
                return b
            } else {
                return nil
            }
        }
        
        if let bus = getExisting() {
            return bus
        } else {
            // setWebView must be run within a synchronized block
            objc_sync_enter(Caravel._defaultInitLock)
            if let bus = getExisting() {
                objc_sync_exit(Caravel._defaultInitLock)
                return bus
            } else {
                _default = Caravel(name: Caravel.DEFAULT_BUS_NAME, webView: webView)
                objc_sync_exit(Caravel._defaultInitLock)
                return _default!
            }
        }
    }
    
    /**
     * Returns custom bus
     */
    public static func get(name: String, webView: UIWebView) -> Caravel {
        if name == Caravel.DEFAULT_BUS_NAME {
            return getDefault(webView)
        } else {
            let getExisting = { () -> Caravel? in
                for b in self._buses {
                    if b.name == name {
                        b.setWebView(webView)
                        return b
                    }
                }
                
                return nil
            }
            
            if let bus = getExisting() {
                return bus
            } else {
                // setWebView must be run within a synchronized block
                objc_sync_enter(Caravel._namedBusInitLock)
                if let bus = getExisting() {
                    objc_sync_exit(Caravel._namedBusInitLock)
                    return bus
                } else {
                    let newBus = Caravel(name: name, webView: webView)
                    _buses.append(newBus)
                    objc_sync_exit(Caravel._namedBusInitLock)
                    return newBus
                }
            }
        }
    }
}