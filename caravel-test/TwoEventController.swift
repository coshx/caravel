import Foundation
import UIKit
import Caravel

open class TwoEventController: BaseController {
    
    @IBOutlet weak var _webView: UIWebView!
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        let tuple = setUp("two_events", webView: _webView)
        let action = {(bus: EventBus) in
            bus.register("FirstEvent") {name, data in
                bus.post("ThirdEvent")
            }
            
            bus.register("NeverTriggeredEvent") {name, data in
                bus.post("FourthEvent")
            }
        }
        
        if BaseController.isUsingWKWebView {
            Caravel.getDefaultReady(self, wkWebView: getWKWebView(), draft: tuple.1!, whenReady: action)
        } else {
            Caravel.getDefault(self, webView: _webView, whenReady: action)
        }
        
        tuple.0()
    }
}
