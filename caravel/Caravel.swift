//        ___           ___           ___           ___           ___           ___           ___
//       /\  \         /\  \         /\  \         /\  \         /\__\         /\  \         /\__\
//      /::\  \       /::\  \       /::\  \       /::\  \       /:/  /        /::\  \       /:/  /
//     /:/\:\  \     /:/\:\  \     /:/\:\  \     /:/\:\  \     /:/  /        /:/\:\  \     /:/  /
//    /:/  \:\  \   /::\~\:\  \   /::\~\:\  \   /::\~\:\  \   /:/__/  ___   /::\~\:\  \   /:/  /
//   /:/__/ \:\__\ /:/\:\ \:\__\ /:/\:\ \:\__\ /:/\:\ \:\__\  |:|  | /\__\ /:/\:\ \:\__\ /:/__/
//   \:\  \  \/__/ \/__\:\/:/  / \/_|::\/:/  / \/__\:\/:/  /  |:|  |/:/  / \:\~\:\ \/__/ \:\  \
//    \:\  \            \::/  /     |:|::/  /       \::/  /   |:|__/:/  /   \:\ \:\__\    \:\  \
//     \:\  \           /:/  /      |:|\/__/        /:/  /     \::::/__/     \:\ \/__/     \:\  \
//      \:\__\         /:/  /       |:|  |         /:/  /       ~~~~          \:\__\        \:\__\
//       \/__/         \/__/         \|__|         \/__/                       \/__/         \/__/

import Foundation
import UIKit

/**
  * @class Caravel
  * @brief Main class of the library. The only public one.
  * Manages all buses and dispatches actions to other components.
  */
public class Caravel: NSObject, UIWebViewDelegate {
    internal static let DEFAULT_BUS_NAME = "default"
    private static let initializationLock = NSObject()
    
    private var secretName: String
    
    /**
     * Bus subscribers
     */
    private lazy var subscribers: [Subscriber] = [Subscriber]()
    
    /**
     * Denotes if the bus has received the init event from JS
     */
    private var isInitialized: Bool
    
    /**
     * Pending initialization subscribers
     */
    private lazy var initializers: [(Caravel) -> Void] = []
    // Initializers are temporary saved in order to prevent them to be garbage
    // collected
    private lazy var onGoingInitializers: [Int: ((Caravel) -> Void)] = [:]
    private lazy var onGoingInitializersId = 0
    
    private var webView: UIWebView
    
    internal init(name: String, webView: UIWebView) {
        self.secretName = name
        self.isInitialized = false
        self.webView = webView
        
        super.init()
        
        UIWebViewDelegateMediator.subscribe(self.webView, subscriber: self)
    }

    /**
     * Sends event to JS
     */
    private func secretPost<T>(eventName: String, eventData: T?) {
        ThreadingHelper.background {
            var data: String?
            var toRun: String?
            
            if let d = eventData {
                try! data = DataSerializer.serialize(d)
            } else {
                data = "null"
            }
            
            if self.secretName == Caravel.DEFAULT_BUS_NAME {
                toRun = "Caravel.getDefault().raise(\"\(eventName)\", \(data!))"
            } else {
                toRun = "Caravel.get(\"\(self.secretName)\").raise(\"\(eventName)\", \(data!))"
            }
            
            ThreadingHelper.main {
                self.webView.stringByEvaluatingJavaScriptFromString(toRun!)
            }
        }
    }
    
    /**
     * If the controller is resumed, the webView may have changed.
     * Caravel has to watch this new component again
     */
    internal func setWebView(webView: UIWebView) {
        // TODO: remove reference from UIWebViewMediator
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
                                
                                ThreadingHelper.main {
                                    i(self)
                                    self.onGoingInitializers.removeValueForKey(index)
                                }
                            }
                            self.initializers = []
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
        ThreadingHelper.background {
            if self.isInitialized {
                ThreadingHelper.main {
                    callback(self)
                }
            } else {
                self.synchronized(Caravel.initializationLock) {
                    if self.isInitialized {
                        ThreadingHelper.main {
                            callback(self)
                        }
                    } else {
                        self.initializers.append(callback)
                    }
                }
            }
        }
    }
    
    /**
      * Posts event without any argument
      */
    public func post(eventName: String) {
        self.secretPost(eventName, eventData: nil as AnyObject?)
    }
    
    /**
      * Posts event with extra data
      */
    public func post<T>(eventName: String, data: T) {
        self.secretPost(eventName, eventData: data)
    }
    
    /**
     * Subscribes to provided event. Callback is run with the event's name and extra data
     */
    public func register(eventName: String, callback: (String, AnyObject?) -> Void) {
        ThreadingHelper.background {
            self.subscribers.append(Subscriber(name: eventName, callback: callback))
        }
    }
    
    /**
     * Returns the default bus
     */
    public static func getDefault(webView: UIWebView) -> Caravel {
        return CaravelFactory.getDefault(webView)
    }
    
    /**
     * Returns custom bus
     */
    public static func get(name: String, webView: UIWebView) -> Caravel {
        return CaravelFactory.get(name, webView: webView)
    }
}