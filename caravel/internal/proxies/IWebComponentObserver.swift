internal protocol IWebComponentObserver: NSObjectProtocol {
    func onMessage(busName: String, eventName: String, eventData: String?)
}