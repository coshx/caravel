import Foundation
import UIKit
import Caravel

class TwoBucketController: UIViewController {
    
    @IBOutlet weak var webView1: UIWebView!
    @IBOutlet weak var webView2: UIWebView!
    
    private var isOtherOneReady = false
    
    override func viewDidLoad() {
        self.isOtherOneReady = false
        
        Caravel.getDefault(self, webView: webView1, whenReadyOnMain: { bus in
            bus.register("Bar") { _, _ in
                print("Bar 1")
            }
            
            if self.isOtherOneReady {
                bus.post("Foo")
            } else {
                self.isOtherOneReady = true
            }
        })
        
        Caravel.getDefault(self, webView: webView2, whenReadyOnMain: { bus in
            bus.register("Bar") { _, _ in
                print("Bar 2")
            }
            
            if self.isOtherOneReady {
                bus.post("Foo")
            } else {
                self.isOtherOneReady = true
            }
        })
        
        webView1.loadRequest(NSURLRequest(URL: NSBundle.mainBundle().URLForResource("two_buckets", withExtension: "html")!))
        webView2.loadRequest(NSURLRequest(URL: NSBundle.mainBundle().URLForResource("two_buckets", withExtension: "html")!))
    }
}