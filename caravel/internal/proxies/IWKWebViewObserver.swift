internal protocol IWKWebViewObserver: NSObjectProtocol {
    func onMessage(busName: String, eventName: String, eventData: AnyObject?)
}