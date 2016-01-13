internal protocol IWKWebViewObserver: IWebComponentObserver {
    func onMessage(busName: String, eventName: String, eventData: AnyObject?)
}