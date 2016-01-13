internal protocol IUIWebViewObserver: IWebComponentObserver {
    func onMessage(busName: String, eventName: String, rawEventData: String?)
}