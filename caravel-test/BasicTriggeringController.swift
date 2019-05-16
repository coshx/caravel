import Foundation
import UIKit
import Caravel
import WebKit

open class BasicTriggeringController: BaseController {

    @IBOutlet weak var _webView: UIWebView!

    open override func viewDidLoad() {
        super.viewDidLoad()

        let tuple = setUp("basic_triggering", webView: _webView)
        let action = { (bus: EventBus) in
            bus.register("From JS") { name, data in
                bus.post("From iOS")
            }
        }

        if BaseController.isUsingWKWebView {
            Caravel.getDefaultReady(self, wkWebView: getWKWebView(), draft: tuple.1!, whenReady: action)
        } else {
            Caravel.getDefault(self, webView: _webView, whenReady: action)
        }

        tuple.0()
    }
}
