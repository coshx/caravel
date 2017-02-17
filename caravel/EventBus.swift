import WebKit
import UIKit

/**
 **EventBus**

 In charge of watching a subscriber / webview-wkwebview pair.
 Deals with any request from the user side, as well as the watched pair, and forward them to the dispatcher.
 */
open class EventBus: NSObject, IUIWebViewObserver, IWKWebViewObserver {

    /**
     **Draft**

     Required when watching a WKWebView
     */
    open class Draft: NSObject, IWKWebViewObserver {
        fileprivate var wkWebViewConfiguration: WKWebViewConfiguration
        internal weak var parent: IWKWebViewObserver?
        internal var hasBeenUsed = false

        internal init(wkWebViewConfiguration: WKWebViewConfiguration) {
            self.wkWebViewConfiguration = wkWebViewConfiguration

            super.init()

            WKScriptMessageHandlerProxyMediator.subscribe(self.wkWebViewConfiguration, observer: self)
        }

        internal func onMessage(_ busName: String, eventName: String, eventData: AnyObject?) {
            self.parent?.onMessage(busName, eventName: eventName, eventData: eventData)
        }
    }

    fileprivate class WKWebViewPair {
        var draft: Draft
        weak var webView: WKWebView?

        init(draft: Draft, webView: WKWebView) throws {
            self.draft = draft
            self.webView = webView

            if draft.hasBeenUsed {
                // If a draft is used twice, the previous listener (parent) is overriden
                // and will never be notified. Hence, prevent this scenario from happening.
                throw CaravelError.draftUsedTwice
            } else {
                self.draft.hasBeenUsed = true
            }
        }
    }

    fileprivate let initializationLock = NSObject()
    fileprivate let subscriberLock = NSObject()

    fileprivate weak var reference: AnyObject?
    fileprivate weak var webView: UIWebView?
    fileprivate var wkWebViewPair: WKWebViewPair?
    fileprivate weak var dispatcher: Caravel?

    /**
     * Bus subscribers
     */
    fileprivate lazy var subscribers: [EventSubscriber] = []

    /**
     * Denotes if the bus has received init event from JS
     */
    fileprivate var isInitialized: Bool

    /**
     * Pending initialization subscribers
     */
    fileprivate lazy var initializers: [(callback: (EventBus) -> Void, inBackground: Bool)] = []
    // Buffer to save initializers temporary, in order to prevent them from being garbage collected
    fileprivate lazy var onGoingInitializers: [Int: (callback: (EventBus) -> Void, inBackground: Bool)] = [:]
    fileprivate lazy var onGoingInitializersId = 0 // Id counter

    fileprivate init(dispatcher: Caravel, reference: AnyObject) {
        self.dispatcher = dispatcher
        self.reference = reference
        self.isInitialized = false

        super.init()
    }

    internal convenience init(dispatcher: Caravel, reference: AnyObject, webView: UIWebView) {
        self.init(dispatcher: dispatcher, reference: reference)
        self.webView = webView

        UIWebViewDelegateProxyMediator.subscribe(self.webView!, observer: self)
    }

    internal convenience init(dispatcher: Caravel, reference: AnyObject, wkWebViewPair: (Draft, WKWebView)) {
        self.init(dispatcher: dispatcher, reference: reference)
        try! self.wkWebViewPair = WKWebViewPair(draft: wkWebViewPair.0, webView: wkWebViewPair.1)

        self.wkWebViewPair!.draft.parent = self
    }

    /**
     * Current name
     */
    open var name: String {
        return self.dispatcher!.name
    }

    fileprivate func unsubscribeFromProxy() {
        if self.isUsingWebView() {
            if let w = self.webView {
                UIWebViewDelegateProxyMediator.unsubscribe(w, observer: self)
            }
        } else {
            if let p = self.wkWebViewPair {
                WKScriptMessageHandlerProxyMediator.unsubscribe(p.draft.wkWebViewConfiguration, observer: self)
            }
        }
    }

    internal func getReference() -> AnyObject? {
        return self.reference
    }

    internal func isUsingWebView() -> Bool {
        return self.webView != nil
    }

    internal func getWebView() -> UIWebView? {
        return self.webView
    }

    internal func getWKWebView() -> WKWebView? {
        return self.wkWebViewPair?.webView
    }

    /**
     Bus is not needed anymore. Stop observing proxy
     */
    internal func notifyAboutCleaning() {
        self.unsubscribeFromProxy()
    }

    /**
     Runs JS script into current context

     - parameter toRun: JS script
     */
    internal func forwardToJS(_ toRun: String) {
        main {
            if self.isUsingWebView() {
                self.webView?.stringByEvaluatingJavaScript(from: toRun)
            } else {
                self.wkWebViewPair?.webView?.evaluateJavaScript(toRun, completionHandler: nil)
            }
        }
    }

    internal func onInit() {
        // Initialization must be run on the main thread. Otherwise, some events would be triggered before onReady
        // has been run and hence be lost.
        if self.isInitialized {
            return
        }

        synchronized(self.initializationLock) {
            if self.isInitialized {
                return
            }

            for pair in self.initializers {
                let index = self.onGoingInitializersId
                let action: ((EventBus) -> Void, Int) -> Void = { initializer, id in
                    initializer(self)
                    self.onGoingInitializers.removeValue(forKey: id)
                }

                self.onGoingInitializers[index] = pair
                self.onGoingInitializersId += 1

                if pair.inBackground {
                    background { action(pair.callback, index) }
                } else {
                    main { action(pair.callback, index) }
                }
            }

            self.initializers = []
            self.isInitialized = true
        }
    }

    /**
     Allows dispatcher to fire any event on this bus

     - parameter name: event's name
     - parameter data: event's data
     */
    internal func raise(_ name: String, data: AnyObject?) {
        synchronized(subscriberLock) {
            for s in self.subscribers {
                if s.name == name {
                    let action = { s.callback(name, data) }

                    if s.inBackground {
                        background(action)
                    } else {
                        main(action)
                    }
                }
            }
        }
    }

    internal func whenReady(_ callback: @escaping (EventBus) -> Void) {
        background {
            if self.isInitialized {
                background {
                    callback(self)
                }
            } else {
                synchronized(self.initializationLock) {
                    if self.isInitialized {
                        background {
                            callback(self)
                        }
                    } else {
                        self.initializers.append((callback, true))
                    }
                }
            }
        }
    }

    internal func whenReadyOnMain(_ callback: @escaping (EventBus) -> Void) {
        background {
            if self.isInitialized {
                main {
                    callback(self)
                }
            } else {
                synchronized(self.initializationLock) {
                    if self.isInitialized {
                        main {
                            callback(self)
                        }
                    } else {
                        self.initializers.append((callback, false))
                    }
                }
            }
        }
    }

    internal static func buildDraft(_ wkWebViewConfiguration: WKWebViewConfiguration) -> Draft {
        return Draft(wkWebViewConfiguration: wkWebViewConfiguration)
    }

    func onMessage(_ busName: String, eventName: String, rawEventData: String?) {
        self.dispatcher?.dispatch(busName, eventName: eventName, rawEventData: rawEventData)
    }

    func onMessage(_ busName: String, eventName: String, eventData: AnyObject?) {
        self.dispatcher?.dispatch(busName, eventName: eventName, eventData: eventData)
    }

    /**
     Posts event

     - parameter eventName: Name of the event
     */
    open func post(_ eventName: String) {
        self.dispatcher?.post(eventName, eventData: nil as AnyObject?)
    }

    /**
     Posts event with extra data

     - parameter eventName: Name of the event
     - parameter data: Data to post (see documentation for supported types)
     */
    open func post<T>(_ eventName: String, data: T) {
        self.dispatcher?.post(eventName, eventData: data)
    }

    /**
     Subscribes to event. Callback is run with the event's name and extra data (if any).

     - parameter eventName: Event to watch
     - parameter callback: Action to run when fired
     */
    open func register(_ eventName: String, callback: @escaping (String, AnyObject?) -> Void) {
        synchronized(subscriberLock) {
            self.subscribers.append(EventSubscriber(name: eventName, callback: callback, inBackground: true))
        }
    }

    /**
     Subscribes to event. Callback is run on main thread with the event's name and extra data (if any).

     - parameter eventName: Event to watch
     - parameter callback: Action to run when fired
     */
    open func registerOnMain(_ eventName: String, callback: @escaping (String, AnyObject?) -> Void) {
        synchronized(subscriberLock) {
            self.subscribers.append(EventSubscriber(name: eventName, callback: callback, inBackground: false))
        }
    }

    /**
     Unregisters subscriber from bus
     */
    open func unregister() {
        self.dispatcher!.deleteBus(self)

        self.unsubscribeFromProxy()

        self.dispatcher = nil
        self.reference = nil
        self.webView = nil
        self.wkWebViewPair = nil
    }
}
