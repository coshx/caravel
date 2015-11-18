//
//  BasicTriggeringController.swift
//  caravel-test
//
//  Created by Adrien on 29/05/15.
//  Copyright (c) 2015 Coshx Labs. All rights reserved.
//

import Foundation
import UIKit
import Caravel

public class BasicTriggeringController: UIViewController {
    
    @IBOutlet weak var _webView: UIWebView!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        Caravel.getDefault(self, webView: _webView, whenReady: { bus in
            bus.register("From JS") { name, data in
                bus.post("From iOS")
            }
        })
        
        _webView.loadRequest(NSURLRequest(URL: NSBundle.mainBundle().URLForResource("basic_triggering", withExtension: "html")!))
    }
}