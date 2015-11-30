import Foundation
import UIKit
import Caravel

class UnregistrationController: UIViewController {
    
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
        Caravel.getDefault(self, webView: webView, whenReady: { bus in
            self.bus = bus
            
            bus.registerOnMain("Whazup?") { _, _ in
                bus.post("Bye")
                self.timer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: "unsubscribe", userInfo: nil, repeats: false)
            }
            
            bus.register("Still around?") { name, _ in
                NSException(name: name, reason: "", userInfo: nil).raise()
            }
            
            bus.post("Hello!")
        })
        
        webView.loadRequest(NSURLRequest(URL: NSBundle.mainBundle().URLForResource("unregistration", withExtension: "html")!))
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Clean webview before exiting
        webView.loadHTMLString("", baseURL: nil)
        webView.delegate = nil
        webView.removeFromSuperview()
    }
    
    func unsubscribe() {
        self.bus!.unregister()
        dispatch_async(dispatch_get_main_queue()) {
            self.timer?.invalidate()
            self.timer = nil
        }
    }
}