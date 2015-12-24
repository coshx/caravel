internal protocol IUIWebViewObserver: NSObjectProtocol {
    func onMessage(busName: String, eventName: String, eventData: String?)
}