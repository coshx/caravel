//
//  TwoEventController.swift
//  caravel-test
//
//  Created by Adrien on 29/05/15.
//  Copyright (c) 2015 Coshx Labs. All rights reserved.
//

import Foundation
import UIKit
import Caravel

public class TwoEventController: UIViewController {
    
    @IBOutlet weak var _webView: UIWebView!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        Caravel.getDefault(_webView).whenReady() { bus in
            bus.register("FirstEvent") { name, data in
                bus.post("ThirdEvent")
            }
            
            bus.register("NeverTriggeredEvent") { name, data in
                bus.post("FourthEvent")
            }
        }
        
        _webView.loadRequest(NSURLRequest(URL: NSBundle.mainBundle().URLForResource("two_events", withExtension: "html")!))
    }
}