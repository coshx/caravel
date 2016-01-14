import Foundation
import UIKit
import Caravel

public class EventNameController: BaseController {
    
    @IBOutlet weak var _webView: UIWebView!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        let tuple = setUp("event_name", webView: _webView)
        let action = {(bus: EventBus) in
            bus.register("Bar") {name, data in
                if name == "Bar" {
                    bus.post("Foo")
                } else {
                    bus.post("Foobar")
                }
            }
        }
        
        if BaseController.isUsingWKWebView {
            Caravel.getDefault(self, wkWebView: getWKWebView(), draft: tuple.1!, whenReady: action)
        } else {
            Caravel.getDefault(self, webView: _webView, whenReady: action)
        }
        
        tuple.0()
    }
}