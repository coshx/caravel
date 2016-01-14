import Foundation
import UIKit
import Caravel

class TwoBucketController: BaseController {
    
    @IBOutlet weak var webView1: UIWebView!
    @IBOutlet weak var webView2: UIWebView!
    
    private var isOtherOneReady = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.isOtherOneReady = false
        
        let tuple1 = setUp("two_buckets", webView: webView1)
        let tuple2 = setUp("two_buckets", webView: webView2)
        let action1 = {(bus: EventBus) in
            bus.register("Bar") {_, _ in
                print("Bar 1")
            }
            
            if self.isOtherOneReady {
                bus.post("Foo")
            } else {
                self.isOtherOneReady = true
            }
        }
        let action2 = {(bus: EventBus) in
            bus.register("Bar") {_, _ in
                print("Bar 2")
            }
            
            if self.isOtherOneReady {
                bus.post("Foo")
            } else {
                self.isOtherOneReady = true
            }
        }
        
        if BaseController.isUsingWKWebView {
            Caravel.getDefault(self, wkWebView: getWKWebView(0), draft: tuple1.1!, whenReady: action1)
            Caravel.getDefault(self, wkWebView: getWKWebView(1), draft: tuple2.1!, whenReady: action2)
        } else {
            Caravel.getDefault(self, webView: webView1, whenReady: action1)
            Caravel.getDefault(self, webView: webView2, whenReady: action2)
        }
        
        tuple1.0()
        tuple2.0()
    }
}