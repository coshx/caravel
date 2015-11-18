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
public class Caravel {
    internal static let DEFAULT_BUS_NAME = "default"
    
    private var secretName: String
    private var buses: [EventBus]
    
    internal init(name: String) {
        self.secretName = name
        self.buses = []
    }

    /**
     * Sends event to JS
     */
    internal func post<T>(eventName: String, eventData: T?) {
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
            
            for b in self.buses {
                b.forwardToJS(toRun!)
            }
        }
    }
    
    internal func addBus(subscriber: AnyObject, webView: UIWebView, whenReady: (EventBus) -> Void, inBackground: Bool) {
        let bus = EventBus(dispatcher: self, reference: subscriber, webView: webView)
        
        self.buses.append(bus)
        if inBackground {
            bus.whenReady(whenReady)
        } else {
            bus.whenReadyOnMain(whenReady)
        }
    }
    
    internal func deleteBus(bus: EventBus) {
        // Run on current thread to avoid locking the list
        var i = 0
        
        for b in self.buses {
            if b == bus {
                self.buses.removeAtIndex(i)
                return
            }
            i++
        }
    }
    
    internal func dispatch(args: (busName: String, eventName: String, eventData: String?)) {
        ThreadingHelper.background {
            var data: AnyObject? = nil
            
            if let d = args.eventData { // Data are optional
                data = DataSerializer.deserialize(d)
            }
            
            for b in self.buses {
                ThreadingHelper.background { b.raise(args.eventName, data: data) }
            }
        }
    }
    
    public var name: String {
        return self.secretName
    }
    
    /**
     * Returns the default bus
     */
    public static func getDefault(subscriber: AnyObject, webView: UIWebView, whenReady: (EventBus) -> Void) -> Caravel {
        let d = CaravelFactory.getDefault()
        d.addBus(subscriber, webView: webView, whenReady: whenReady, inBackground: true)
        return d
    }
    
    public static func getDefault(subscriber: AnyObject, webView: UIWebView, whenReadyOnMain: (EventBus) -> Void) -> Caravel {
        let d = CaravelFactory.getDefault()
        d.addBus(subscriber, webView: webView, whenReady: whenReadyOnMain, inBackground: false)
        return d
    }
    
    /**
     * Returns custom bus
     */
    public static func get(subscriber: AnyObject, name: String, webView: UIWebView, whenReady: (EventBus) -> Void) -> Caravel {
        let d = CaravelFactory.get(name)
        d.addBus(subscriber, webView: webView, whenReady: whenReady, inBackground: true)
        return d
    }
    
    public static func get(subscriber: AnyObject, name: String, webView: UIWebView, whenReadyOnMain: (EventBus) -> Void) -> Caravel {
        let d = CaravelFactory.get(name)
        d.addBus(subscriber, webView: webView, whenReady: whenReadyOnMain, inBackground: false)
        return d
    }
}