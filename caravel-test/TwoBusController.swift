//
//  TwoBusController.swift
//  caravel-test
//
//  Created by Adrien on 29/05/15.
//  Copyright (c) 2015 Coshx Labs. All rights reserved.
//

import Foundation
import UIKit
import Caravel

public class TwoBusController: UIViewController {
    
    @IBOutlet weak var _webView: UIWebView!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        Caravel.get(self, name: "FooBus", webView: _webView, whenReady: { bus in
            bus.post("AnEvent")
        })
        
        Caravel.get(self, name: "BarBus", webView: _webView, whenReady: { bus in
            bus.post("AnEvent")
        })
        
        _webView.loadRequest(NSURLRequest(URL: NSBundle.mainBundle().URLForResource("two_buses", withExtension: "html")!))
    }
}