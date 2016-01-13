import Foundation
import UIKit
import Caravel
import WebKit

public class BasicTriggeringController: UIViewController {
    
    @IBOutlet weak var _webView: UIWebView!
    private var wkWebView: WKWebView?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        let config = WKWebViewConfiguration()
        let draft = Caravel.getDraft(config)
        wkWebView = WKWebView(frame: self._webView.frame, configuration: config)
        self._webView.removeFromSuperview()
        self.view.addSubview(wkWebView!)
        
        Caravel.getDefault(self, wkWebView: wkWebView!, draft: draft, whenReady: {bus in
                bus.register("From JS") {name, data in
                    bus.post("From iOS")
                }
            })
        
        self.wkWebView!.loadRequest(NSURLRequest(URL: NSBundle.mainBundle().URLForResource("basic_triggering", withExtension: "html")!))
        
//        Caravel.getDefault(self, webView: _webView, whenReady: {bus in
//                bus.register("From JS") {name, data in
//                    bus.post("From iOS")
//                }
//            })
//
//        _webView.loadRequest(NSURLRequest(URL: NSBundle.mainBundle().URLForResource("basic_triggering", withExtension: "html")!))
    }
}