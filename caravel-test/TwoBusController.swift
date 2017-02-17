import Foundation
import UIKit
import Caravel
import WebKit

open class TwoBusController: UIViewController {
    
    @IBOutlet weak var _webView: UIWebView!
    fileprivate var wkWebView: WKWebView?
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        let request = URLRequest(url: Bundle.main.url(forResource: "two_buses", withExtension: "html")!)
        let action = {(bus: EventBus) in
            bus.post("AnEvent")
        }
        
        if BaseController.isUsingWKWebView {
            let config = WKWebViewConfiguration()
            let draft1 = Caravel.getDraft(config), draft2 = Caravel.getDraft(config)
            
            self.wkWebView = WKWebView(frame: _webView.frame, configuration: config)
            _webView.removeFromSuperview()
            self.view.addSubview(self.wkWebView!)
            
            Caravel.get(self, name: "FooBus", wkWebView: self.wkWebView!, draft: draft1, whenReady: action)
            Caravel.get(self, name: "BarBus", wkWebView: self.wkWebView!, draft: draft2, whenReady: action)
            
            self.wkWebView!.load(request)
        } else {
            Caravel.get(self, name: "FooBus", webView: _webView, whenReady: action)
            Caravel.get(self, name: "BarBus", webView: _webView, whenReady: action)
            _webView.loadRequest(request)
        }
    }
}
