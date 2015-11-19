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
    
    private func _raise(name: String) {
        NSException(name: name, reason: "", userInfo: nil).raise()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        Caravel.getDefault(self, webView: _webView, whenReady: { bus in
            bus.post("Bool", data: true)
            bus.post("Int", data: 42)
            bus.post("Float", data: 19.92)
            bus.post("Double", data: 20.15)
            bus.post("String", data: "Churchill")
            bus.post("HazardousString", data: "There is a \" and a '")
            bus.post("Array", data: [1, 2, 3, 5])
            bus.post("Dictionary", data: ["foo": 45, "bar": 89])
            bus.post("ComplexArray", data: [["name": "Alice", "age": 24], ["name": "Bob", "age": 23]])
            bus.post("ComplexDictionary", data: ["name": "Cesar", "address": ["street": "Parrot", "city": "Perigueux"], "games": ["Fifa", "Star Wars"]])
            
            bus.register("True") { name, data in
                if let b = data as? Bool {
                    if b != true {
                        self._raise("True - bad value")
                    }
                } else {
                    self._raise("True - bad type")
                }
            }
            
            bus.register("False") { name, data in
                if let b = data as? Bool {
                    if b != false {
                        self._raise("False - bad value")
                    }
                } else {
                    self._raise("False - bad type")
                }
            }
            
            bus.register("Int") { name, data in
                if let i = data as? Int {
                    if i != 987 {
                        self._raise("Int - bad value")
                    }
                } else {
                    self._raise("Int - bad type")
                }
            }
            
            bus.register("Float") { name, data in
                if let f = data as? Float {
                    if f != 19.89 {
                        self._raise("Float - bad value")
                    }
                } else {
                    self._raise("Float - bad type")
                }
            }
            
            bus.register("Double") { name, data in
                if let d = data as? Double {
                    if d != 15.15 {
                        self._raise("Double - bad value")
                    }
                } else {
                    self._raise("Double - bad type")
                }
            }
            
            bus.register("String") { name, data in
                if let s = data as? String {
                    if s != "Napoleon" {
                        self._raise("String - bad value")
                    }
                } else {
                    self._raise("String - bad type")
                }
            }
            
            bus.register("UUID") { name, data in
                if let s = data as? String {
                    if s != "9658ae60-9e0d-4da7-a63d-46fe75ff1db1" {
                        self._raise("UUID - bad value")
                    }
                } else {
                    self._raise("UUID - bad type")
                }
            }
            
            bus.register("Array") { name, data in
                if let a = data as? NSArray {
                    if a.count != 3 {
                        self._raise("Array - bad length")
                    }
                    if a[0] as! Int != 3 {
                        self._raise("Array - bad first element")
                    }
                    if a[1] as! Int != 1 {
                        self._raise("Array - bad second element")
                    }
                    if a[2] as! Int != 4 {
                        self._raise("Array - bad third element")
                    }
                } else {
                    self._raise("Array - bad type")
                }
            }
            
            bus.register("Dictionary") { name, data in
                if let d = data as? NSDictionary {
                    if d.count != 2 {
                        self._raise("Dictionary - bad length")
                    }
                    if d.valueForKey("movie") as! String != "Once upon a time in the West" {
                        self._raise("Dictionary - bad first pair")
                    }
                    if d.valueForKey("actor") as! String != "Charles Bronson" {
                        self._raise("Dictionary - bad second pair")
                    }
                } else {
                    self._raise("Dictionary - bad type")
                }
            }
            
            bus.register("ComplexArray") { name, data in
                if let a = data as? NSArray {
                    if a.count != 3 {
                        self._raise("ComplexArray - bad length")
                    }
                    if a[0] as! Int != 87 {
                        self._raise("ComplexArray - bad first element")
                    }
                    if let d = a[1] as? NSDictionary {
                        if d.valueForKey("name") as! String != "Bruce Willis" {
                            self._raise("ComplexArray - bad second element")
                        }
                    } else {
                        self._raise("ComplexArray - bad typed second element")
                    }
                    if a[2] as! String != "left-handed" {
                        self._raise("ComplexArray - bad third element")
                    }
                } else {
                    self._raise("ComplexArray - bad type")
                }
            }
            
            bus.register("ComplexDictionary") { name, data in
                if let d = data as? NSDictionary {
                    if d.valueForKey("name") as! String != "John Malkovich" {
                        self._raise("ComplexDictionary - bad first pair")
                    }
                    
                    if let a = d.valueForKey("movies") as? NSArray {
                        if a.count != 2 {
                            self._raise("ComplexDictionary - bad length")
                        }
                        if a[0] as! String != "Dangerous Liaisons" {
                            self._raise("ComplexDictionary - bad first element in array")
                        }
                        if a[1] as! String != "Burn after reading" {
                            self._raise("ComplexDictionary - bad second element in array")
                        }
                    } else {
                        self._raise("ComplexDictionary - bad typed second element")
                    }
                    
                    if d.valueForKey("kids") as! Int != 2 {
                        self._raise("ComplexDictionary - bad third pair")
                    }
                } else {
                    self._raise("ComplexDictionary - bad type")
                }
            }
        })
        
        _webView.loadRequest(NSURLRequest(URL: NSBundle.mainBundle().URLForResource("event_data", withExtension: "html")!))
    }
}