/**
 * @class EventBus
 * @brief In charge of watching a subscriber / webview pair.
 * If any event is captured, it forwards it to dispatcher (except init one).
 * Argument passed as well when whenReady callback is run.
 */
public class EventBus: NSObject, UIWebViewDelegate {
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
        
        UIWebViewDelegateMediator.subscribe(self.webView!, subscriber: self)
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
        ThreadingHelper.main {
            self.webView?.stringByEvaluatingJavaScriptFromString(toRun)
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
                        ThreadingHelper.background(action)
                    } else {
                        ThreadingHelper.main(action)
                    }
                }
            }
        }
    }
    
    internal func whenReady(callback: (EventBus) -> Void) {
        ThreadingHelper.background {
            if self.isInitialized {
                ThreadingHelper.background {
                    callback(self)
                }
            } else {
                self.synchronized(self.initializationLock) {
                    if self.isInitialized {
                        ThreadingHelper.background {
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
        ThreadingHelper.background {
            if self.isInitialized {
                ThreadingHelper.main {
                    callback(self)
                }
            } else {
                self.synchronized(self.initializationLock) {
                    if self.isInitialized {
                        ThreadingHelper.main {
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
    public func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if let scheme: String = request.URL?.scheme {
            if scheme == "caravel" {
                let args = ArgumentParser.parse(request.URL!.query!)
                
                // All buses are notified about that incoming event. Then, each bus has to investigate first if it
                // is a potential receiver
                if self.dispatcher?.name == args.busName {
                    if args.eventName == "CaravelInit" && !self.isInitialized { // Reserved event name. Triggers whenReady
                        // Initialization must be run on the main thread. Otherwise, some events would be triggered before onReady
                        // has been run and hence be lost.
                        // Also, this function has to return if the request should be blocked or not.
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
                                ThreadingHelper.background { action(pair.callback, index) }
                            } else {
                                ThreadingHelper.main { action(pair.callback, index) }
                            }
                        }
                        
                        self.initializers = []
                    } else {
                        self.dispatcher?.dispatch(args)
                    }
                }
                
                // As it is a custom URL, webview shall not run it
                return false
            }
            
            return true
        }
        
        return true
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
        UIWebViewDelegateMediator.unsubscribe(self.webView!, subscriber: self)
        self.dispatcher = nil
        self.reference = nil
        self.webView = nil
    }
}