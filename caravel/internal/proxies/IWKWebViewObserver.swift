internal protocol IWKWebViewObserver: NSObjectProtocol {
    func onMessage(_ busName: String, eventName: String, eventData: AnyObject?)
}
