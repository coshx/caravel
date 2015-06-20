//
//  HazardousDataController.swift
//  caravel-test
//
//  Created by Adrien on 19/06/15.
//  Copyright (c) 2015 Coshx Labs. All rights reserved.
//

import Foundation
import UIKit
import Caravel

public class HazardousDataController: UIViewController {
    
    @IBOutlet weak var _webView: UIWebView!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        Caravel.get("@D@ngerousBus@", webView: _webView).whenReady() { bus in
            bus.register("@D@ngerousEvent") { name, data in
                var s = data as! String
                
                if s != "@@@" {
                    NSException(name: "@@@", reason: "", userInfo: nil)
                }
            }
        }
        
        _webView.loadRequest(NSURLRequest(URL: NSBundle.mainBundle().URLForResource("hazardous_data", withExtension: "html")!))
    }
}