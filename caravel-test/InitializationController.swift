import Foundation
import UIKit
import Caravel

open class InitializationController: BaseController {
    
    @IBOutlet weak var _webView: UIWebView!
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        let tuple = setUp("initialization", webView: _webView)
        let action = {(bus: EventBus) in
            bus.post("Before")
        }
        let action2 = {(bus: EventBus) in
            bus.post("After")
        }
        
        if BaseController.isUsingWKWebView {
            Caravel.getDefaultReady(self, wkWebView: getWKWebView(), draft: tuple.1!, whenReady: action)
        } else {
            Caravel.getDefault(self, webView: _webView, whenReady: action)
        }
        
        tuple.0()
        
        if BaseController.isUsingWKWebView {
            Caravel.getDefaultReady(self, wkWebView: getWKWebView(), draft: tuple.1!, whenReady: action2)
        } else {
            Caravel.getDefault(self, webView: _webView, whenReady: action2)
        }
    }
}
