import UIKit
import UIKit
import Caravel
import WebKit

public class BaseController: UIViewController {
    static var isUsingWKWebView = false
    
    private lazy var wkWebViews = [WKWebView]()
    private lazy var wkWebViewConfigurations = [WKWebViewConfiguration]()
    
    func getWKWebView() -> WKWebView {
        return wkWebViews[0]
    }
    
    func getWKWebView(index: Int) -> WKWebView {
        return wkWebViews[index]
    }
    
    func getWKWebViewConfiguration() -> WKWebViewConfiguration {
        return wkWebViewConfigurations[0]
    }
    
    func getWKWebViewConfiguration(index: Int) -> WKWebViewConfiguration {
        return wkWebViewConfigurations[index]
    }
    
    func setUp(page: String, webView: UIWebView) -> (Void -> Void, EventBus.Draft?) {
        var draft: EventBus.Draft?
        var action: (Void -> Void)?
        let request = NSURLRequest(URL: NSBundle.mainBundle().URLForResource(page, withExtension: "html")!)
        
        if BaseController.isUsingWKWebView {
            let config = WKWebViewConfiguration()
            let view = WKWebView(frame: webView.frame, configuration: config)
            
            self.wkWebViewConfigurations.append(config)
            self.wkWebViews.append(view)
            draft = Caravel.getDraft(config)
            webView.removeFromSuperview()
            self.view.addSubview(view)
            
            action = {view.loadRequest(request)}
        } else {
            action = {webView.loadRequest(request)}
        }
        
        return (action!, draft)
    }
}