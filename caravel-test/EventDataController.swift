//
//  EventDataController.swift
//  caravel-test
//
//  Created by Adrien on 29/05/15.
//  Copyright (c) 2015 Coshx Labs. All rights reserved.
//

import Foundation
import UIKit
import Caravel

public class EventDataController: UIViewController {
    
    @IBOutlet weak var _webView: UIWebView!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        Caravel.getDefault(_webView).whenReady() { bus in
            bus.post("Bool", aBool: true)
            bus.post("Int", anInt: 42)
            bus.post("Float", aFloat: 19.92)
            bus.post("Double", aDouble: 20.15)
            bus.post("String", aString: "Churchill")
            bus.post("Array", anArray: [1, 2, 3, 5])
            bus.post("Dictionary", aDictionary: ["foo": 45, "bar": 89])
            bus.post("ComplexArray", anArray: [["name": "Alice", "age": 24], ["name": "Bob", "age": 23]])
            bus.post("ComplexDictionary", aDictionary: ["name": "Cesar", "address": ["street": "Parrot", "city": "Perigueux"], "games": ["Fifa", "Star Wars"]])
            
            bus.register("Int") { name, data in
                if (data as? Int) != 987 {
                    NSException().raise()
                }
            }
            
            bus.register("Float") { name, data in
                if (data as? Float) != 19.89 {
                    NSException().raise()
                }
            }
            
            bus.register("Double") { name, data in
                if (data as? Double) != 15.15 {
                    NSException().raise()
                }
            }
            
            bus.register("String") { name, data in
                if (data as? String) != "Napoleon" {
                    NSException().raise()
                }
            }
        }
        
        _webView.loadRequest(NSURLRequest(URL: NSBundle.mainBundle().URLForResource("event_data", withExtension: "html")!))
    }
}