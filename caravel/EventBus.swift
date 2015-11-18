public class EventBus: NSObject, UIWebViewDelegate {
    private let initializationLock = NSObject()
    
    private weak var reference: AnyObject?
    private weak var webView: UIWebView?
    private weak var dispatcher: Caravel?
    
    /**
     * Bus subscribers
     */
    private lazy var subscribers: [EventSubscriber] = []
    
    /**
     * Denotes if the bus has received the init event from JS
     */
    private var isInitialized: Bool
    
    /**
     * Pending initialization subscribers
     */
    private lazy var initializers: [(callback: (EventBus) -> Void, inBackground: Bool)] = []
    // Initializers are temporary saved in order to prevent them from being garbage collected
    private lazy var onGoingInitializers: [Int: (callback: (EventBus) -> Void, inBackground: Bool)] = [:]
    private lazy var onGoingInitializersId = 0
    
    internal init(dispatcher: Caravel, reference: AnyObject, webView: UIWebView) {
        self.dispatcher = dispatcher
        self.reference = reference
        self.isInitialized = false
        self.webView = webView
        
        super.init()
        
        UIWebViewDelegateMediator.subscribe(self.webView!, subscriber: self)
    }
    
    internal func getReference() -> AnyObject? {
        return self.reference
    }
    
    internal func getWebView() -> UIWebView? {
        return self.webView
    }
    
    internal func forwardToJS(toRun: String) {
        ThreadingHelper.main {
            self.webView?.stringByEvaluatingJavaScriptFromString(toRun)
        }
    }
    
    internal func raise(name: String, data: AnyObject?) {
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
    
    public func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if let scheme: String = request.URL?.scheme {
            if scheme == "caravel" {
                let args = ArgumentParser.parse(request.URL!.query!)
                
                // All buses are notified about that incoming event. Then, they need to investigate first if they
                // are potential receivers
                if self.dispatcher?.name == args.busName {
                    if args.eventName == "CaravelInit" && !self.isInitialized { // Reserved event name. Triggers whenReady
                        // Initialization must be run on the main thread. Otherwise, some events would be triggered before onReady
                        // has been run and hence be lost.
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
                
                // As it is a custom URL, we need to prevent the webview from running it
                return false
            }
            
            return true
        }
        
        return true
    }
    
    func whenReady(callback: (EventBus) -> Void) {
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
    
    func whenReadyOnMain(callback: (EventBus) -> Void) {
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
     * Posts event without any argument
     */
    public func post(eventName: String) {
        self.dispatcher?.post(eventName, eventData: nil as AnyObject?)
    }
    
    /**
     * Posts event with extra data
     */
    public func post<T>(eventName: String, data: T) {
        self.dispatcher?.post(eventName, eventData: data)
    }
    
    /**
     * Subscribes to provided event. Callback is run with the event's name and extra data
     */
    public func register(eventName: String, callback: (String, AnyObject?) -> Void) {
        self.subscribers.append(EventSubscriber(name: eventName, callback: callback, inBackground: true))
    }
    
    public func registerOnMain(eventName: String, callback: (String, AnyObject?) -> Void) {
        self.subscribers.append(EventSubscriber(name: eventName, callback: callback, inBackground: false))
    }
    
    public func unregister(subscriber: AnyObject) {
        if subscriber.hash == self.reference?.hash {
            self.dispatcher!.deleteBus(self)
            UIWebViewDelegateMediator.unsubscribe(self.webView!, subscriber: self)
            self.reference = nil
            self.webView = nil
        }
    }
}