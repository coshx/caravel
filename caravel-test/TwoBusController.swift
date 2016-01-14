import Foundation
import UIKit
import Caravel
import WebKit

public class TwoBusController: UIViewController {
    
    @IBOutlet weak var _webView: UIWebView!
    private var wkWebView: WKWebView?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        let request = NSURLRequest(URL: NSBundle.mainBundle().URLForResource("two_buses", withExtension: "html")!)
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
            
            self.wkWebView!.loadRequest(request)
        } else {
            Caravel.get(self, name: "FooBus", webView: _webView, whenReady: action)
            Caravel.get(self, name: "BarBus", webView: _webView, whenReady: action)
            _webView.loadRequest(request)
        }
    }
}