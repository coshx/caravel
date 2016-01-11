import WebKit

/**
 * @class EventBus
 * @brief In charge of watching a subscriber / webview pair.
 * If any event is captured, it forwards it to dispatcher (except init one).
 * Argument passed as well when whenReady callback is run.
 */
public class EventBus: NSObject, IUIWebViewObserver, IWKWebViewObserver {
    
    public class Draft: NSObject, IWKWebViewObserver {
        private var wkWebViewConfiguration: WKWebViewConfiguration
        internal weak var parent: IWKWebViewObserver?
        
        init(wkWebViewConfiguration: WKWebViewConfiguration) {
            self.wkWebViewConfiguration = wkWebViewConfiguration
            
            super.init()
            
            WKScriptMessageHandlerProxyMediator.subscribe(self.wkWebViewConfiguration, observer: self)
        }
        
        func onMessage(busName: String, eventName: String, eventData: String?) {
            self.parent?.onMessage(busName, eventName: eventName, eventData: eventData)
        }
    }
    
    private class WKWebViewPair {
        var draft: Draft
        weak var webView: WKWebView?
        
        init(draft: Draft, webView: WKWebView) {
            self.draft = draft
            self.webView = webView
        }
    }
    
    private let initializationLock = NSObject()
    private let subscriberLock = NSObject()
    
    private weak var reference: AnyObject?
    private weak var webView: UIWebView?
    private var wkWebViewPair: WKWebViewPair?
    private weak var dispatcher: Caravel?
    
    /**
     * Bus subscribers
     */
    private lazy var subscribers: [EventSubscriber] = []
    
    /**
     * Denotes if the bus has received init event from JS
     */
    private var isInitialized: Bool
    
    /**
     * Pending initialization subscribers
     */
    private lazy var initializers: [(callback: (EventBus) -> Void, inBackground: Bool)] = []
    // Buffer to save initializers temporary, in order to prevent them from being garbage collected
    private lazy var onGoingInitializers: [Int: (callback: (EventBus) -> Void, inBackground: Bool)] = [:]
    private lazy var onGoingInitializersId = 0 // Id counter
    
    private init(dispatcher: Caravel, reference: AnyObject) {
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
        self.wkWebViewPair = WKWebViewPair(draft: wkWebViewPair.0, webView: wkWebViewPair.1)
        
        self.wkWebViewPair!.draft.parent = self
    }
    
    /**
     * Current name
     */
    public var name: String {
        return self.dispatcher!.name
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
     * Runs JS script into current context
     */
    internal func forwardToJS(toRun: String) {
        main {
            if self.isUsingWebView() {
                self.webView?.stringByEvaluatingJavaScriptFromString(toRun)
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
                let action: ((EventBus) -> Void, Int) -> Void = {initializer, id in
                    initializer(self)
                    self.onGoingInitializers.removeValueForKey(id)
                }
                
                self.onGoingInitializers[index] = pair
                self.onGoingInitializersId++
                
                if pair.inBackground {
                    background {action(pair.callback, index)}
                } else {
                    main {action(pair.callback, index)}
                }
            }
            
            self.initializers = []
            self.isInitialized = true
        }
    }
    
    /**
     * Allows dispatcher to fire any event on this bus
     */
    internal func raise(name: String, data: AnyObject?) {
        synchronized(subscriberLock) {
            for s in self.subscribers {
                if s.name == name {
                    let action = {s.callback(name, data)}
                    
                    if s.inBackground {
                        background(action)
                    } else {
                        main(action)
                    }
                }
            }
        }
    }
    
    internal func whenReady(callback: (EventBus) -> Void) {
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
    
    internal func whenReadyOnMain(callback: (EventBus) -> Void) {
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
    
    internal static func buildDraft(wkWebViewConfiguration: WKWebViewConfiguration) -> Draft {
        return Draft(wkWebViewConfiguration: wkWebViewConfiguration)
    }
    
    /**
     * Engines potential event firing from JS
     */
    func onMessage(busName: String, eventName: String, eventData: String?) {
        self.dispatcher?.dispatch(busName, eventName: eventName, eventData: eventData)
    }
    
    /**
     * Posts event
     * @param eventName Event's name
     */
    public func post(eventName: String) {
        self.dispatcher?.post(eventName, eventData: nil as AnyObject?)
    }
    
    /**
     * Posts event with extra data
     * @param eventName Event's name
     * @param data Data to post (see documentation for supported types)
     */
    public func post<T>(eventName: String, data: T) {
        self.dispatcher?.post(eventName, eventData: data)
    }
    
    /**
     * Subscribes to event. Callback is run with the event's name and extra data (if any).
     * @param eventName Event to watch
     * @param callback Action to run when fired
     */
    public func register(eventName: String, callback: (String, AnyObject?) -> Void) {
        synchronized(subscriberLock) {
            self.subscribers.append(EventSubscriber(name: eventName, callback: callback, inBackground: true))
        }
    }
    
    /**
     * Subscribes to event. Callback is run on main thread with the event's name and extra data (if any).
     * @param eventName Event to watch
     * @param callback Action to run when fired
     */
    public func registerOnMain(eventName: String, callback: (String, AnyObject?) -> Void) {
        synchronized(subscriberLock) {
            self.subscribers.append(EventSubscriber(name: eventName, callback: callback, inBackground: false))
        }
    }
    
    /**
     * Unregisters subscriber from bus
     */
    public func unregister() {
        self.dispatcher!.deleteBus(self)
        
        if self.isUsingWebView() {
            if let w = self.webView {
                UIWebViewDelegateProxyMediator.unsubscribe(w, observer: self)
            }
        } else {
            if let p = self.wkWebViewPair {
                WKScriptMessageHandlerProxyMediator.unsubscribe(p.draft.wkWebViewConfiguration, observer: self)
            }
        }
        
        self.dispatcher = nil
        self.reference = nil
        self.webView = nil
        self.wkWebViewPair = nil
    }
}