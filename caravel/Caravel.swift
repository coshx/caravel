//
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
 **Caravel**

 Main class of the library. Dispatches events among buses.
 */
open class Caravel {
    fileprivate let busLock = NSObject()
    internal static let DefaultBusName = "default"

    fileprivate var secretName: String
    fileprivate var buses: [EventBus]

    internal init(name: String) {
        self.secretName = name
        self.buses = []
    }

    fileprivate func lockBuses(_ action: @escaping () -> Void) {
        synchronized(busLock) {
            action()
        }
    }

    fileprivate func addBus(_ bus: EventBus, whenReady: @escaping (EventBus) -> Void, inBackground: Bool) {
        self.lockBuses { self.buses.append(bus) }

        if inBackground {
            bus.whenReady(whenReady)
        } else {
            bus.whenReadyOnMain(whenReady)
        }

        background { // Clean unused buses
            self.lockBuses {
                var i = 0
                var toRemove: [Int] = []

                for b in self.buses {
                    if (b.getReference() == nil && b.getWebView() == nil) || (b.getReference() == nil && b.getWKWebView() == nil) {
                        // Watched pair was garbage collected. This bus is not needed anymore
                        toRemove.append(i)
                        b.notifyAboutCleaning()
                    }
                    i += 1
                }

                i = 0
                for j in toRemove {
                    self.buses.remove(at: j - i)
                    i += 1
                }
            }
        }
    }

    fileprivate func addBus(_ subscriber: AnyObject, webView: UIWebView, whenReady: @escaping (EventBus) -> Void, inBackground: Bool) {
        // Test first if an existing bus matching provided pair already exists
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

    fileprivate func addBus(_ subscriber: AnyObject, wkWebView: WKWebView, draft: EventBus.Draft, whenReady: @escaping (EventBus) -> Void, inBackground: Bool) {
        // Test first if an existing bus matching provided pair already exists
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

    fileprivate static func testSubscriber(_ subscriber: AnyObject, target: AnyObject) throws {
        if subscriber.hash == target.hash {
            throw CaravelError.subscriberIsSameThanTarget
        }
    }

    internal func post<T>(_ eventName: String, eventData: T?) {
        background {
            var data: String?
            var toRun: String?

            if let d = eventData {
                try! data = DataSerializer.serialize(d)
            } else {
                data = "null"
            }

            toRun = "Caravel."

            if self.secretName == Caravel.DefaultBusName {
                toRun!.append("getDefault()")
            } else {
                toRun!.append("get(\"\(self.secretName)\")")
            }

            toRun!.append(".raise(\"\(eventName)\", \(data!))")

            self.lockBuses {
                for b in self.buses {
                    b.forwardToJS(toRun!)
                }
            }
        }
    }

    internal func deleteBus(_ bus: EventBus) {
        self.lockBuses {
            var i = 0

            for b in self.buses {
                if b == bus {
                    self.buses.remove(at: i)
                    return
                }
                i += 1
            }
        }
    }

    internal func dispatch(_ busName: String, eventName: String, eventData: AnyObject?) {
        if busName != self.name {
            // Different buses can use the same web view so same proxy
            // If not a potential receiver, ignore event
            return
        }

        if eventName == "CaravelInit" { // Reserved event name. Triggers whenReady
            self.lockBuses {
                for b in self.buses {
                    b.onInit() // Run on main/current thread
                }
            }
        } else {
            background {
                self.lockBuses {
                    for b in self.buses {
                        background { b.raise(eventName, data: eventData) }
                    }
                }
            }
        }
    }

    internal func dispatch(_ busName: String, eventName: String, rawEventData: String?) {
        if busName != self.name {
            return
        }

        var data: AnyObject?
        if let d = rawEventData { // Data are optional
            data = DataSerializer.deserialize(d)
        }

        self.dispatch(busName, eventName: eventName, eventData: data)
    }

    /**
     Current name
     */
    open var name: String {
        return self.secretName
    }

    /**
     Returns default bus

     - parameter subscriber: Subscriber (usually the view controller)
     - parameter webView: WebView to watch
     - parameter whenReady: Action to run when bus is ready to use

     - returns: Current instance
     */
    public static func getDefault(_ subscriber: AnyObject, webView: UIWebView, whenReady: @escaping (EventBus) -> Void) -> Caravel {
        let d = CaravelFactory.getDefault()
        try! testSubscriber(subscriber, target: webView)
        d.addBus(subscriber, webView: webView, whenReady: whenReady, inBackground: true)
        return d
    }

    /**
     Returns default bus and runs callback on main thread

     - parameter subscriber: Subscriber (usually the view controller)
     - parameter webView: WebView to watch
     - parameter whenReadyOnMain: Action to run when bus is ready to use

     - returns: Current instance
     */
    public static func getDefault(_ subscriber: AnyObject, webView: UIWebView, whenReadyOnMain: @escaping (EventBus) -> Void) -> Caravel {
        let d = CaravelFactory.getDefault()
        try! testSubscriber(subscriber, target: webView)
        d.addBus(subscriber, webView: webView, whenReady: whenReadyOnMain, inBackground: false)
        return d
    }

    /**
     Returns custom bus

     - parameter subscriber: Subscriber (usually the view controller)
     - parameter name: Bus name
     - parameter webView: WebView to watch
     - parameter whenReady: Action to run when bus is ready to use

     - returns: Current instance
     */
    public static func get(_ subscriber: AnyObject, name: String, webView: UIWebView, whenReady: @escaping (EventBus) -> Void) -> Caravel {
        let d = CaravelFactory.get(name)
        try! testSubscriber(subscriber, target: webView)
        d.addBus(subscriber, webView: webView, whenReady: whenReady, inBackground: true)
        return d
    }

    /**
     Returns custom bus and runs callback on main thread

     - parameter subscriber: Subscriber (usually the view controller)
     - parameter name: Bus name
     - parameter webView: WebView to watch
     - parameter whenReadyOnMain: Action to run when bus is ready to use

     - returns: Current instance
     */
    public static func get(_ subscriber: AnyObject, name: String, webView: UIWebView, whenReadyOnMain: @escaping (EventBus) -> Void) -> Caravel {
        let d = CaravelFactory.get(name)
        try! testSubscriber(subscriber, target: webView)
        d.addBus(subscriber, webView: webView, whenReady: whenReadyOnMain, inBackground: false)
        return d
    }

    /**
     Builds draft for single use with provided WKWebView configuration

     - parameter configuration: Custom WKWebView configuration

     - returns: Bus draft
     */
    public static func getDraft(_ configuration: WKWebViewConfiguration) -> EventBus.Draft {
        return EventBus.buildDraft(configuration)
    }

    /**
     Returns default bus

     - parameter subscriber: Subscriber (usually the view controller)
     - parameter wkWebView: WKWebView to watch
     - parameter draft: EventBus draft that has been built before initializing the view
     - parameter whenReady: Action to run when bus is ready to use

     - returns: Current instance
     */
    public static func getDefaultReady(_ subscriber: AnyObject, wkWebView: WKWebView, draft: EventBus.Draft, whenReady: @escaping (EventBus) -> Void) -> Caravel {
        let d = CaravelFactory.getDefault()
        try! testSubscriber(subscriber, target: wkWebView)
        d.addBus(subscriber, wkWebView: wkWebView, draft: draft, whenReady: whenReady, inBackground: true)
        return d
    }

    /**
     Returns default bus and runs callback on main thread

     - parameter subscriber: Subscriber (usually the view controller)
     - parameter wkWebView: WKWebView to watch
     - parameter draft: EventBus draft that has been built before initializing the view
     - parameter whenReadyOnMain: Action to run when bus is ready to use

     - returns: Current instance
     */
    public static func getDefaultReadyOnMain(_ subscriber: AnyObject, wkWebView: WKWebView, draft: EventBus.Draft, whenReadyOnMain: @escaping (EventBus) -> Void) -> Caravel {
        let d = CaravelFactory.getDefault()
        try! testSubscriber(subscriber, target: wkWebView)
        d.addBus(subscriber, wkWebView: wkWebView, draft: draft, whenReady: whenReadyOnMain, inBackground: false)
        return d
    }

    /**
     Returns default bus

     - parameter subscriber: Subscriber (usually the view controller)
     - parameter name: Bus name
     - parameter wkWebView: WKWebView to watch
     - parameter draft: EventBus draft that has been built before initializing the view
     - parameter whenReady: Action to run when bus is ready to use

     - returns: Current instance
     */
    public static func get(_ subscriber: AnyObject, name: String, wkWebView: WKWebView, draft: EventBus.Draft, whenReady: @escaping (EventBus) -> Void) -> Caravel {
        let d = CaravelFactory.get(name)
        try! testSubscriber(subscriber, target: wkWebView)
        d.addBus(subscriber, wkWebView: wkWebView, draft: draft, whenReady: whenReady, inBackground: true)
        return d
    }

    /**
     Returns default bus and runs callback on main thread

     - parameter subscriber: Subscriber (usually the view controller)
     - parameter name: Bus name
     - parameter wkWebView: WKWebView to watch
     - parameter draft: EventBus draft that has been built before initializing the view
     - parameter whenReadyOnMain: Action to run when bus is ready to use

     - returns: Current instance
     */
    public static func get(_ subscriber: AnyObject, name: String, wkWebView: WKWebView, draft: EventBus.Draft, whenReadyOnMain: @escaping (EventBus) -> Void) -> Caravel {
        let d = CaravelFactory.get(name)
        try! testSubscriber(subscriber, target: wkWebView)
        d.addBus(subscriber, wkWebView: wkWebView, draft: draft, whenReady: whenReadyOnMain, inBackground: false)
        return d
    }
}
