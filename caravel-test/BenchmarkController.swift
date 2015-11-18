import Foundation
import UIKit
import Caravel

class BenchmarkController: UIViewController {
    @IBOutlet weak var webView: UIWebView!
    
    private weak var bus: EventBus?
    
    override func viewDidLoad() {
        Caravel.getDefault(self, webView: webView, whenReady: {
            self.bus = $0
        })
        
        webView.loadRequest(NSURLRequest(URL: NSBundle.mainBundle().URLForResource("benchmark", withExtension: "html")!))
    }
    
    
    @IBAction func onStart(sender: AnyObject) {
        let name = NSUUID().UUIDString
        
        Caravel.get(self, name: name, webView: webView, whenReady: { bus in
            for i in 0..<1000 {
                bus.register("Background-\(i)") { name, _ in
                    bus.post("\(name)-confirmation")
                }
                
                bus.registerOnMain("Main-\(i)") { name, _ in
                    bus.post("\(name)-confirmation")
                }
            }
            
            bus.post("Ready")
        })
        
        self.bus!.post("BusName", data: name)
    }
}