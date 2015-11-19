import Foundation
import UIKit
import Caravel

class UnregistrationController: UIViewController {
    
    @IBOutlet weak var webView: UIWebView!
    private weak var bus: EventBus?
    
    override func viewDidLoad() {
        Caravel.getDefault(self, webView: webView, whenReady: { bus in
            self.bus = bus
            
            bus.registerOnMain("Whazup?") { _, _ in
                bus.post("Bye")
                NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: "unsubscribe", userInfo: nil, repeats: false)
            }
            
            bus.register("Still around?") { name, _ in
                NSException(name: name, reason: "", userInfo: nil).raise()
            }
            
            bus.post("Hello!")
        })
        
        webView.loadRequest(NSURLRequest(URL: NSBundle.mainBundle().URLForResource("unregistration", withExtension: "html")!))
    }
    
    func unsubscribe() {
        bus!.unregister(self)
    }
}