internal protocol IUIWebViewObserver: NSObjectProtocol {
    func onMessage(_ busName: String, eventName: String, rawEventData: String?)
}
