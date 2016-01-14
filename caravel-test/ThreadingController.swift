import Foundation
import UIKit
import Caravel
import WebKit

class ThreadingController: UIViewController {
    
    @IBOutlet weak var webView: UIWebView!
    private var wkWebView: WKWebView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let request = NSURLRequest(URL: NSBundle.mainBundle().URLForResource("threading", withExtension: "html")!)
        let action1 = {(bus: EventBus) in
            bus.registerOnMain("FromJSForBackground") {_, _ in
                bus.post("FromBackgroundAfterFromJS")
            }
            
            sleep(1)
            
            bus.post("FromBackground")
        }
        let action2 = {(bus: EventBus) in
            bus.register("FromJSForMain") {_, _ in
                sleep(2)
                bus.post("FromMainAfterFromJS")
            }
            
            bus.post("FromMain")
        }
        
        if BaseController.isUsingWKWebView {
            let config = WKWebViewConfiguration()
            let draft1 = Caravel.getDraft(config), draft2 = Caravel.getDraft(config)
            
            self.wkWebView = WKWebView(frame: webView.frame, configuration: config)
            webView.removeFromSuperview()
            self.view.addSubview(self.wkWebView!)
            
            Caravel.get(self, name: "First", wkWebView: self.wkWebView!, draft: draft1, whenReady: action1)
            Caravel.get(self, name: "Second", wkWebView: self.wkWebView!, draft: draft2, whenReadyOnMain: action2)
            
            self.wkWebView!.loadRequest(request)
        } else {
            Caravel.get(self, name: "First", webView: webView, whenReady: action1)
            Caravel.get(self, name: "Second", webView: webView, whenReadyOnMain: action2)
            webView.loadRequest(request)
        }
    }
}