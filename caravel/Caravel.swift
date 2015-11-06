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
    private static var defaultBus: Caravel?
    private static var buses: [Caravel] = [Caravel]()
    
    private var secretName: String
    
    /**
     * Bus subscribers
     */
    private lazy var subscribers: [Subscriber] = [Subscriber]()
    
    /**
     * Denotes if the bus has received the init event from JS
     */
    private var isInitialized: Bool
    
    // Multithreading locks
    private static var defaultInitLock = NSObject()
    private static var namedBusInitLock = NSObject()
    
    /**
     * Pending initialization subscribers
     */
    private lazy var initializers: [(Caravel) -> Void] = []
    // Initializers are temporary saved in order to prevent them to be garbage
    // collected
    private lazy var onGoingInitializers: [Int: ((Caravel) -> Void)] = [:]
    private lazy var onGoingInitializersId = 0
    
    private var webView: UIWebView
    
    private init(name: String, webView: UIWebView) {
        self.secretName = name
        self.isInitialized = false
        self.webView = webView
        
        super.init()
        
        UIWebViewDelegateMediator.subscribe(self.webView, subscriber: self)
    }

    /**
     * Sends event to JS
     */
    private func post(eventName: String, eventData: AnyObject?, type: SupportedType?) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            var toRun: String?
            var data: String?
            
            if let d: AnyObject = eventData {
                data = DataSerializer.serialize(d, type: type!)
            } else {
                data = "null"
            }
            
            if self.secretName == Caravel.DEFAULT_BUS_NAME {
                toRun = "Caravel.getDefault().raise(\"\(eventName)\", \(data!))"
            } else {
                toRun = "Caravel.get(\"\(self.secretName)\").raise(\"\(eventName)\", \(data!))"
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                self.webView.stringByEvaluatingJavaScriptFromString(toRun!)
            }
        }
    }
    
    /**
     * If the controller is resumed, the webView may have changed.
     * Caravel has to watch this new component again
     */
    internal func setWebView(webView: UIWebView) {
        if webView.hash == self.webView.hash {
            return
        }
        // whenReady() should be triggered only after a CaravelInit event
        // has been raised (aka wait for JS before calling whenReady)
        self.isInitialized = false
        self.webView = webView
        self.subscribers = []
        UIWebViewDelegateMediator.subscribe(self.webView, subscriber: self)
    }
    
    internal func synchronized(action: () -> Void) {
        let lock = (self.secretName == Caravel.DEFAULT_BUS_NAME) ? Caravel.defaultInitLock : Caravel.namedBusInitLock
        
        objc_sync_enter(lock)
        action()
        objc_sync_exit(lock)
    }
    
    public var name: String {
        return self.secretName
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
                if self.secretName == args.busName {
                    if args.eventName == "CaravelInit" { // Reserved event name. Triggers whenReady
                        if !self.isInitialized {
                            self.isInitialized = true
                            
                            for i in self.initializers {
                                let index = self.onGoingInitializersId
                                
                                self.onGoingInitializers[index] = i
                                self.onGoingInitializersId++
                                
                                dispatch_async(dispatch_get_main_queue()) {
                                    i(self)
                                    self.onGoingInitializers.removeValueForKey(index)
                                }
                            }
                            self.initializers = Array<(Caravel) -> Void>()
                        }
                    } else {
                        var eventData: AnyObject? = nil
                        
                        if let d = args.eventData { // Data are optional
                            eventData = DataSerializer.deserialize(d)
                        }
                        
                        for s in self.subscribers {
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
        if self.isInitialized {
            dispatch_async(dispatch_get_main_queue()) {
                callback(self)
            }
        } else {
            self.synchronized {
                if self.isInitialized {
                    dispatch_async(dispatch_get_main_queue()) {
                        callback(self)
                    }
                } else {
                    self.initializers.append(callback)
                }
            }
        }
    }
    
    /**
     * Posts event without any argument
     */
    public func post(eventName: String) {
        self.post(eventName, eventData: nil, type: nil)
    }
    
    /**
    * Posts event with an extra int
    */
    public func post(eventName: String, anInt: Int) {
        self.post(eventName, eventData: anInt, type: .Int)
    }
    
    /**
    * Posts event with an extra bool
    */
    public func post(eventName: String, aBool: Bool) {
        self.post(eventName, eventData: aBool, type: .Bool)
    }
    
    /**
    * Posts event with an extra double
    */
    public func post(eventName: String, aDouble: Double) {
        self.post(eventName, eventData: aDouble, type: .Double)
    }
    
    /**
    * Posts event with an extra float
    */
    public func post(eventName: String, aFloat: Float) {
        self.post(eventName, eventData: aFloat, type: .Float)
    }
    
    /**
    * Posts event with an extra string
    */
    public func post(eventName: String, aString: String) {
        self.post(eventName, eventData: aString, type: .String)
    }
    
    /**
    * Posts event with an extra array
    */
    public func post(eventName: String, anArray: NSArray) {
        self.post(eventName, eventData: anArray, type: .Array)
    }
    
    /**
    * Posts event with an extra dictionary
    */
    public func post(eventName: String, aDictionary: NSDictionary) {
        self.post(eventName, eventData: aDictionary, type: .Dictionary)
    }
    
    /**
     * Subscribes to provided event. Callback is run with the event's name and extra data
     */
    public func register(eventName: String, callback: (String, AnyObject?) -> Void) {
        self.subscribers.append(Subscriber(name: eventName, callback: callback))
    }
    
    /**
     * Returns the default bus
     */
    public static func getDefault(webView: UIWebView) -> Caravel {
        let getExisting = { () -> Caravel? in
            if let b = Caravel.defaultBus {
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
            objc_sync_enter(Caravel.defaultInitLock)
            if let bus = getExisting() {
                objc_sync_exit(Caravel.defaultInitLock)
                return bus
            } else {
                self.defaultBus = Caravel(name: Caravel.DEFAULT_BUS_NAME, webView: webView)
                objc_sync_exit(Caravel.defaultInitLock)
                return self.defaultBus!
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
                for b in self.buses {
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
                objc_sync_enter(Caravel.namedBusInitLock)
                if let bus = getExisting() {
                    objc_sync_exit(Caravel.namedBusInitLock)
                    return bus
                } else {
                    let newBus = Caravel(name: name, webView: webView)
                    self.buses.append(newBus)
                    objc_sync_exit(Caravel.namedBusInitLock)
                    return newBus
                }
            }
        }
    }
}