import Foundation
import UIKit
import Caravel

class UnregistrationController: BaseController {
    
    class WeakWrapper {
        weak var wrapped: UnregistrationController?
        
        init(wrapped: UnregistrationController) {
            self.wrapped = wrapped
        }
        
        func unsubscribe() {
            self.wrapped?.unsubscribe()
        }
    }
    
    @IBOutlet weak var webView: UIWebView!
    private weak var bus: EventBus?
    private weak var timer: NSTimer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tuple = setUp("unregistration", webView: webView)
        let action = {(bus: EventBus) in
            self.bus = bus
            
            bus.registerOnMain("Whazup?") {_, _ in
                bus.post("Bye")
                self.timer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: "unsubscribe", userInfo: nil, repeats: false)
            }
            
            bus.register("Still around?") {name, _ in
                NSException(name: name, reason: "", userInfo: nil).raise()
            }
            
            bus.post("Hello!")
        }
        
        if BaseController.isUsingWKWebView {
            Caravel.getDefault(self, wkWebView: getWKWebView(), draft: tuple.1!, whenReady: action)
        } else {
            Caravel.getDefault(self, webView: webView, whenReady: action)
        }
        
        tuple.0()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        if !BaseController.isUsingWKWebView {
            // Clean webview before exiting
            webView.loadHTMLString("", baseURL: nil)
            webView.delegate = nil
            webView.removeFromSuperview()
        }
    }
    
    func unsubscribe() {
        self.bus!.unregister()
        self.timer?.invalidate()
        self.timer = nil
    }
}