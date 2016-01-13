import UIKit
import UIKit
import Caravel
import WebKit

public class BaseController: UIViewController {
    static var isUsingWKWebView = false
    
    private var wkWebView: WKWebView?
    
    func getWKWebView() -> WKWebView {
        return wkWebView!
    }
    
    func setUp(page: String, webView: UIWebView) -> (Void -> Void, EventBus.Draft?) {
        var draft: EventBus.Draft?
        var action: (Void -> Void)?
        let request = NSURLRequest(URL: NSBundle.mainBundle().URLForResource(page, withExtension: "html")!)
        
        if BaseController.isUsingWKWebView {
            let config = WKWebViewConfiguration()
            draft = Caravel.getDraft(config)
            self.wkWebView = WKWebView(frame: webView.frame, configuration: config)
            webView.removeFromSuperview()
            self.view.addSubview(self.wkWebView!)
            
            action = {self.wkWebView!.loadRequest(request)}
        } else {
            action = {webView.loadRequest(request)}
        }
        
        return (action!, draft)
    }
}