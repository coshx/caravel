import Foundation
import UIKit
import Caravel
import WebKit

class BenchmarkController: UIViewController {
    @IBOutlet weak var webView: UIWebView!
    
    fileprivate weak var bus: EventBus?
    fileprivate var wkWebView: WKWebView?
    fileprivate var draftForBenchmarking: EventBus.Draft?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let request = URLRequest(url: Bundle.main.url(forResource: "benchmark", withExtension: "html")!)
        let action = {(bus: EventBus) in
            self.bus = bus
        }
        
        if BaseController.isUsingWKWebView {
            let config = WKWebViewConfiguration()
            let draft = Caravel.getDraft(config)
            self.draftForBenchmarking = Caravel.getDraft(config)
            
            self.wkWebView = WKWebView(frame: webView.frame, configuration: config)
            webView.removeFromSuperview()
            self.view.addSubview(self.wkWebView!)
            
            Caravel.getDefault(self, wkWebView: self.wkWebView!, draft: draft, whenReady: action)
            
            self.wkWebView!.load(request)
        } else {
            Caravel.getDefault(self, webView: webView, whenReady: action)
            webView.loadRequest(request)
        }
    }
    
    @IBAction func onStart(_ sender: AnyObject) {
        let name = UUID().uuidString
        let action = {(bus: EventBus) in
            for i in 0..<1000 {
                bus.register("Background-\(i)") {name, _ in
                    bus.post("\(name)-confirmation")
                }
                
                bus.registerOnMain("Main-\(i)") {name, _ in
                    bus.post("\(name)-confirmation")
                }
            }
            
            bus.post("Ready")
        }
        
        if BaseController.isUsingWKWebView {
            Caravel.get(self, name: name, wkWebView: self.wkWebView!, draft: self.draftForBenchmarking!, whenReady: action)
        } else {
            Caravel.get(self, name: name, webView: webView, whenReady: action)
        }
        
        self.bus!.post("BusName", data: name)
    }
}
