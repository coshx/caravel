import Foundation
import UIKit
import Caravel

class ThreadingController: UIViewController {
    
    @IBOutlet weak var webView: UIWebView!
    
    override func viewDidLoad() {
        
        Caravel.get(self, name: "First", webView: webView, whenReady: { bus in
            bus.registerOnMain("FromJSForBackground") { _, _ in
                bus.post("FromBackgroundAfterFromJS")
            }
            
            sleep(1)
            
            bus.post("FromBackground")
        })
        
        Caravel.get(self, name: "Second", webView: webView, whenReadyOnMain: { bus in
            bus.register("FromJSForMain") { _, _ in
                sleep(2)
                bus.post("FromMainAfterFromJS")
            }
            
            bus.post("FromMain")
        })
        
        webView.loadRequest(NSURLRequest(URL: NSBundle.mainBundle().URLForResource("threading", withExtension: "html")!))
    }
}