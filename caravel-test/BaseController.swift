import UIKit
import UIKit
import Caravel
import WebKit

open class BaseController: UIViewController {
    static var isUsingWKWebView = false
    
    fileprivate lazy var wkWebViews = [WKWebView]()
    fileprivate lazy var wkWebViewConfigurations = [WKWebViewConfiguration]()
    
    func getWKWebView() -> WKWebView {
        return wkWebViews[0]
    }
    
    func getWKWebView(_ index: Int) -> WKWebView {
        return wkWebViews[index]
    }
    
    func getWKWebViewConfiguration() -> WKWebViewConfiguration {
        return wkWebViewConfigurations[0]
    }
    
    func getWKWebViewConfiguration(_ index: Int) -> WKWebViewConfiguration {
        return wkWebViewConfigurations[index]
    }
    
    func setUp(_ page: String, webView: UIWebView) -> ((Void) -> Void, EventBus.Draft?) {
        var draft: EventBus.Draft?
        var action: (Void) -> Void
        let request = URLRequest(url: Bundle.main.url(forResource: page, withExtension: "html")!)
        
        if BaseController.isUsingWKWebView {
            let config = WKWebViewConfiguration()
            let view = WKWebView(frame: webView.frame, configuration: config)
            
            self.wkWebViewConfigurations.append(config)
            self.wkWebViews.append(view)
            draft = Caravel.getDraft(config)
            webView.removeFromSuperview()
            self.view.addSubview(view)
            
            action = {view.load(request)}
        } else {
            action = {webView.loadRequest(request)}
        }
        
        return (action, draft)
    }
}
