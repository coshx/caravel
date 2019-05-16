import Foundation
import UIKit
import Caravel

open class MultipleSubscriberController: BaseController {
    
    @IBOutlet weak var _webView: UIWebView!
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        let tuple = setUp("multiple_subscribers", webView: _webView)
        let action = {(bus: EventBus) in
            bus.post("AnEvent")
        }
        
        if BaseController.isUsingWKWebView {
            Caravel.getDefaultReady(self, wkWebView: getWKWebView(), draft: tuple.1!, whenReady: action)
        } else {
            Caravel.getDefault(self, webView: _webView, whenReady: action)
        }
        
        tuple.0()
    }
}
