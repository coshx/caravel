internal protocol IUIWebViewObserver: NSObjectProtocol {
    func onMessage(busName: String, eventName: String, rawEventData: String?)
}