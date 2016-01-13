
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
import WebKit

/**
 * @class Caravel
 * @brief Main class of the library. Dispatches events among buses.
 */
public class Caravel {
    private let busLock = NSObject()
    internal static let DEFAULT_BUS_NAME = "default"
    
    private var secretName: String
    private var buses: [EventBus]
    
    internal init(name: String) {
        self.secretName = name
        self.buses = []
    }
    
    private func lockBuses(@noescape action: () -> Void) {
        synchronized(busLock) {
            action()
        }
    }
    
    private func addBus(bus: EventBus, whenReady: (EventBus) -> Void, inBackground: Bool) {
        self.lockBuses {self.buses.append(bus)}
        if inBackground {
            bus.whenReady(whenReady)
        } else {
            bus.whenReadyOnMain(whenReady)
        }
        
        background {// Clean unused buses
            self.lockBuses {
                var i = 0
                var toRemove: [Int] = []
                
                for b in self.buses {
                    if (b.getReference() == nil && b.getWebView() == nil) || (b.getReference() == nil && b.getWKWebView() == nil) {
                        // Watched pair was garbage collected. This bus is not needed anymore
                        toRemove.append(i)
                    }
                    i++
                }
                
                i = 0
                for j in toRemove {
                    self.buses.removeAtIndex(j - i)
                    i++
                }
            }
        }
    }
    
    private func addBus(subscriber: AnyObject, webView: UIWebView, whenReady: (EventBus) -> Void, inBackground: Bool) {
        // Test if an existing bus matching provided pair already exists
        objc_sync_enter(busLock)
        for b in self.buses {
            if b.isUsingWebView() && b.getReference()?.hash == subscriber.hash && b.getWebView()?.hash == webView.hash {
                if inBackground {
                    b.whenReady(whenReady)
                } else {
                    b.whenReadyOnMain(whenReady)
                }
                objc_sync_exit(busLock)
                return
            }
        }
        objc_sync_exit(busLock)
        
        let bus = EventBus(dispatcher: self, reference: subscriber, webView: webView)
        self.addBus(bus, whenReady: whenReady, inBackground: inBackground)
    }
    
    private func addBus(subscriber: AnyObject, wkWebView: WKWebView, draft: EventBus.Draft, whenReady: (EventBus) -> Void, inBackground: Bool) {
        // Test if an existing bus matching provided pair already exists
        objc_sync_enter(busLock)
        for b in self.buses {
            if !b.isUsingWebView() && b.getReference()?.hash == subscriber.hash && b.getWKWebView()?.hash == wkWebView.hash {
                if inBackground {
                    b.whenReady(whenReady)
                } else {
                    b.whenReadyOnMain(whenReady)
                }
                objc_sync_exit(busLock)
                return
            }
        }
        objc_sync_exit(busLock)
        
        let bus = EventBus(dispatcher: self, reference: subscriber, wkWebViewPair: (draft, wkWebView))
        self.addBus(bus, whenReady: whenReady, inBackground: inBackground)
    }
    
    internal func post<T>(eventName: String, eventData: T?) {
        background {
            var data: String?
            var toRun: String?
            
            if let d = eventData {
                try! data = DataSerializer.serialize(d)
            } else {
                data = "null"
            }
            
            toRun = "Caravel."
            
            if self.secretName == Caravel.DEFAULT_BUS_NAME {
                toRun!.appendContentsOf("getDefault()")
            } else {
                toRun!.appendContentsOf("get(\"\(self.secretName)\")")
            }
            
            toRun!.appendContentsOf(".raise(\"\(eventName)\", \(data!))")
            
            self.lockBuses {
                for b in self.buses {
                    b.forwardToJS(toRun!)
                }
            }
        }
    }
    
    internal func deleteBus(bus: EventBus) {
        self.lockBuses {
            var i = 0
            
            for b in self.buses {
                if b == bus {
                    self.buses.removeAtIndex(i)
                    return
                }
                i++
            }
        }
    }
    
    internal func dispatch(busName: String, eventName: String, rawEventData: String?) {
        if busName != self.name {
            return
        }
        
        var data: AnyObject?
        if let d = rawEventData {// Data are optional
            data = DataSerializer.deserialize(d)
        }
        
        self.dispatch(busName, eventName: eventName, eventData: data)
    }
    
    internal func dispatch(busName: String, eventName: String, eventData: AnyObject?) {
        if busName != self.name {
            return
        }
        
        if eventName == "CaravelInit" {// Reserved event name. Triggers whenReady
            self.lockBuses {
                for b in self.buses {
                    b.onInit()
                }
            }
        } else {
            background {
                self.lockBuses {
                    for b in self.buses {
                        background {b.raise(eventName, data: eventData)}
                    }
                }
            }
        }
    }
    
    /**
     * Current name
     */
    public var name: String {
        return self.secretName
    }
    
    /**
     * Returns default bus
     * @param subscriber Subscriber
     * @param webView WebView to watch
     * @param whenReady Action to run when JS counterpart is ready
     */
    public static func getDefault(subscriber: AnyObject, webView: UIWebView, whenReady: (EventBus) -> Void) -> Caravel {
        let d = CaravelFactory.getDefault()
        d.addBus(subscriber, webView: webView, whenReady: whenReady, inBackground: true)
        return d
    }
    
    /**
     * Returns default bus and run callback on main thread
     * @param subscriber Subscriber
     * @param webView WebView to watch
     * @param whenReadyOnMain Action to run when JS counterpart is ready
     */
    public static func getDefault(subscriber: AnyObject, webView: UIWebView, whenReadyOnMain: (EventBus) -> Void) -> Caravel {
        let d = CaravelFactory.getDefault()
        d.addBus(subscriber, webView: webView, whenReady: whenReadyOnMain, inBackground: false)
        return d
    }
    
    /**
     * Returns custom bus
     * @param subscriber Subscriber
     * @param name Bus name
     * @param webView WebView to watch
     * @param whenReady Action to run when JS counterpart is ready
     */
    public static func get(subscriber: AnyObject, name: String, webView: UIWebView, whenReady: (EventBus) -> Void) -> Caravel {
        let d = CaravelFactory.get(name)
        d.addBus(subscriber, webView: webView, whenReady: whenReady, inBackground: true)
        return d
    }
    
    /**
     * Returns custom bus and run callback on main thread
     * @param subscriber Subscriber
     * @param name Bus name
     * @param webView WebView to watch
     * @param whenReadyOnMain Action to run when JS counterpart is ready
     */
    public static func get(subscriber: AnyObject, name: String, webView: UIWebView, whenReadyOnMain: (EventBus) -> Void) -> Caravel {
        let d = CaravelFactory.get(name)
        d.addBus(subscriber, webView: webView, whenReady: whenReadyOnMain, inBackground: false)
        return d
    }
    
    public static func getDraft(configuration: WKWebViewConfiguration) -> EventBus.Draft {
        return EventBus.buildDraft(configuration)
    }
    
    /**
     * Returns default bus
     * @param subscriber Subscriber
     * @param webView WebView to watch
     * @param whenReady Action to run when JS counterpart is ready
     */
    public static func getDefault(subscriber: AnyObject, wkWebView: WKWebView, draft: EventBus.Draft, whenReady: (EventBus) -> Void) -> Caravel {
        let d = CaravelFactory.getDefault()
        d.addBus(subscriber, wkWebView: wkWebView, draft: draft, whenReady: whenReady, inBackground: true)
        return d
    }
    
    /**
     * Returns default bus and run callback on main thread
     * @param subscriber Subscriber
     * @param webView WebView to watch
     * @param whenReadyOnMain Action to run when JS counterpart is ready
     */
    public static func getDefault(subscriber: AnyObject, wkWebView: WKWebView, draft: EventBus.Draft, whenReadyOnMain: (EventBus) -> Void) -> Caravel {
        let d = CaravelFactory.getDefault()
        d.addBus(subscriber, wkWebView: wkWebView, draft: draft, whenReady: whenReadyOnMain, inBackground: false)
        return d
    }
    
    /**
     * Returns custom bus
     * @param subscriber Subscriber
     * @param name Bus name
     * @param webView WebView to watch
     * @param whenReady Action to run when JS counterpart is ready
     */
    public static func get(subscriber: AnyObject, name: String, wkWebView: WKWebView, draft: EventBus.Draft, whenReady: (EventBus) -> Void) -> Caravel {
        let d = CaravelFactory.get(name)
        d.addBus(subscriber, wkWebView: wkWebView, draft: draft, whenReady: whenReady, inBackground: true)
        return d
    }
    
    /**
     * Returns custom bus and run callback on main thread
     * @param subscriber Subscriber
     * @param name Bus name
     * @param webView WebView to watch
     * @param whenReadyOnMain Action to run when JS counterpart is ready
     */
    public static func get(subscriber: AnyObject, name: String, wkWebView: WKWebView, draft: EventBus.Draft, whenReadyOnMain: (EventBus) -> Void) -> Caravel {
        let d = CaravelFactory.get(name)
        d.addBus(subscriber, wkWebView: wkWebView, draft: draft, whenReady: whenReadyOnMain, inBackground: false)
        return d
    }
}