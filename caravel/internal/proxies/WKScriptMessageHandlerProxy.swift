import WebKit

/**
 **WKScriptMessageHandlerProxy**

 Sets up a custom script message handler for the provided configuration
 */
internal class WKScriptMessageHandlerProxy: NSObject, WKScriptMessageHandler {
    fileprivate let subscriberLock = NSObject()

    /**
     All the subscribers.
     */
    fileprivate lazy var subscribers: [IWKWebViewObserver] = []

    init(configuration: WKWebViewConfiguration) {
        super.init()

        configuration.userContentController.add(self, name: "caravel")
    }

    fileprivate func lockSubscribers(_ action: () -> Void) {
        synchronized(subscriberLock, action: action)
    }

    fileprivate func iterateOverDelegates(_ callback: (IWKWebViewObserver) -> Void) {
        self.lockSubscribers {
            for e in self.subscribers {
                callback(e)
            }
        }
    }

    func subscribe(_ subscriber: IWKWebViewObserver) {
        lockSubscribers {
            for s in self.subscribers {
                if s.hash == subscriber.hash {
                    return
                }
            }

            self.subscribers.append(subscriber)
        }
    }

    func unsubscribe(_ subscriber: IWKWebViewObserver) {
        lockSubscribers {
            var i = 0
            for e in self.subscribers {
                if e.hash == subscriber.hash {
                    self.subscribers.remove(at: i)
                    return
                }
                i += 1
            }
        }
    }

    func hasSubscribers() -> Bool {
        return self.subscribers.count > 0
    }

    func willBeDeleted(_ config: WKWebViewConfiguration) {
        config.userContentController.removeScriptMessageHandler(forName: "caravel")
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        let body = message.body as! Dictionary<String, AnyObject>
        let busName = body["busName"] as! String
        let eventName = body["eventName"] as! String
        let eventData = body["eventData"]

        iterateOverDelegates { e in
            e.onMessage(busName, eventName: eventName, eventData: eventData)
        }
    }
}
