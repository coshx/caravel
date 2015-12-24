/**
 * @class EventBus
 * @brief In charge of watching a subscriber / webview pair.
 * If any event is captured, it forwards it to dispatcher (except init one).
 * Argument passed as well when whenReady callback is run.
 */
public class EventBus: NSObject, IUIWebViewObserver {
    private let initializationLock = NSObject()
    private let subscriberLock = NSObject()
    
    private weak var reference: AnyObject?
    private weak var webView: UIWebView?
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
    
    internal init(dispatcher: Caravel, reference: AnyObject, webView: UIWebView) {
        self.dispatcher = dispatcher
        self.reference = reference
        self.isInitialized = false
        self.webView = webView
        
        super.init()
        
        UIWebViewDelegateProxyMediator.subscribe(self.webView!, observer: self)
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
    
    internal func getWebView() -> UIWebView? {
        return self.webView
    }
    
    /**
     * Runs JS script into current context
     */
    internal func forwardToJS(toRun: String) {
        main {
            self.webView?.stringByEvaluatingJavaScriptFromString(toRun)
        }
    }
    
    internal func onInit() {
        // Initialization must be run on the main thread. Otherwise, some events would be triggered before onReady
        // has been run and hence be lost.
        if self.isInitialized {
            return
        }
        
        synchronized(self.initializationLock) {
            self.isInitialized = true
            
            for pair in self.initializers {
                let index = self.onGoingInitializersId
                let action: ((EventBus) -> Void, Int) -> Void = { initializer, id in
                    initializer(self)
                    self.onGoingInitializers.removeValueForKey(id)
                }
                
                self.onGoingInitializers[index] = pair
                self.onGoingInitializersId++
                
                if pair.inBackground {
                    background { action(pair.callback, index) }
                } else {
                    action(pair.callback, index)
                }
            }
            
            self.initializers = []
        }
    }
    
    /**
     * Allows dispatcher to fire any event on this bus
     */
    internal func raise(name: String, data: AnyObject?) {
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
        UIWebViewDelegateProxyMediator.unsubscribe(self.webView!, observer: self)
        self.dispatcher = nil
        self.reference = nil
        self.webView = nil
    }
}