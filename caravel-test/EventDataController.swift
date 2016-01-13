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

public class EventDataController: BaseController {
    
    @IBOutlet weak var _webView: UIWebView!
    
    private func _raise(name: String) {
        NSException(name: name, reason: "", userInfo: nil).raise()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        let tuple = setUp("event_data", webView: _webView)
        let action = {(bus: EventBus) in
            bus.post("Bool", data: true)
            bus.post("Int", data: 42)
            bus.post("Float", data: 19.92)
            bus.post("Double", data: 20.15)
            bus.post("String", data: "Churchill")
            bus.post("HazardousString", data: "There is a \" and a '")
            bus.post("Array", data: [1, 2, 3, 5])
            bus.post("Dictionary", data: ["foo": 45, "bar": 89])
            bus.post("ComplexArray", data: [["name": "Alice", "age": 24], ["name": "Bob", "age": 23]])
            bus.post("ComplexDictionary", data: ["name": "Paul", "address": ["street": "Hugo", "city": "Bordeaux"], "games": ["Fifa", "Star Wars"]])
            
            bus.register("True") {name, data in
                if let b = data as? Bool {
                    if b != true {
                        self._raise("True - wrong value")
                    }
                } else {
                    self._raise("True - wrong type")
                }
            }
            
            bus.register("False") {name, data in
                if let b = data as? Bool {
                    if b != false {
                        self._raise("False - wrong value")
                    }
                } else {
                    self._raise("False - wrong type")
                }
            }
            
            bus.register("Int") {name, data in
                if let i = data as? Int {
                    if i != 987 {
                        self._raise("Int - wrong value")
                    }
                } else {
                    self._raise("Int - wrong type")
                }
            }
            
            bus.register("Double") {name, data in
                if let d = data as? Double {
                    if d != 15.15 {
                        self._raise("Double - wrong value")
                    }
                } else {
                    self._raise("Double - wrong type")
                }
            }
            
            bus.register("String") {name, data in
                if let s = data as? String {
                    if s != "Napoleon" {
                        self._raise("String - wrong value")
                    }
                } else {
                    self._raise("String - wrong type")
                }
            }
            
            bus.register("UUID") {name, data in
                if let s = data as? String {
                    if s != "9658ae60-9e0d-4da7-a63d-46fe75ff1db1" {
                        self._raise("UUID - wrong value")
                    }
                } else {
                    self._raise("UUID - wrong type")
                }
            }
            
            bus.register("Array") {name, data in
                if let a = data as? NSArray {
                    if a.count != 3 {
                        self._raise("Array - wrong length")
                    }
                    if a[0] as! Int != 3 {
                        self._raise("Array - wrong first element")
                    }
                    if a[1] as! Int != 1 {
                        self._raise("Array - wrong second element")
                    }
                    if a[2] as! Int != 4 {
                        self._raise("Array - wrong third element")
                    }
                } else {
                    self._raise("Array - wrong type")
                }
            }
            
            bus.register("Dictionary") {name, data in
                if let d = data as? NSDictionary {
                    if d.count != 2 {
                        self._raise("Dictionary - wrong length")
                    }
                    if d.valueForKey("movie") as! String != "Once upon a time in the West" {
                        self._raise("Dictionary - wrong first pair")
                    }
                    if d.valueForKey("actor") as! String != "Charles Bronson" {
                        self._raise("Dictionary - wrong second pair")
                    }
                } else {
                    self._raise("Dictionary - wrong type")
                }
            }
            
            bus.register("ComplexArray") {name, data in
                if let a = data as? NSArray {
                    if a.count != 3 {
                        self._raise("ComplexArray - wrong length")
                    }
                    if a[0] as! Int != 87 {
                        self._raise("ComplexArray - wrong first element")
                    }
                    if let d = a[1] as? NSDictionary {
                        if d.valueForKey("name") as! String != "Bruce Willis" {
                            self._raise("ComplexArray - wrong second element")
                        }
                    } else {
                        self._raise("ComplexArray - wrong typed second element")
                    }
                    if a[2] as! String != "left-handed" {
                        self._raise("ComplexArray - wrong third element")
                    }
                } else {
                    self._raise("ComplexArray - wrong type")
                }
            }
            
            bus.register("ComplexDictionary") {name, data in
                if let d = data as? NSDictionary {
                    if d.valueForKey("name") as! String != "John Malkovich" {
                        self._raise("ComplexDictionary - wrong first pair")
                    }
                    
                    if let a = d.valueForKey("movies") as? NSArray {
                        if a.count != 2 {
                            self._raise("ComplexDictionary - wrong length")
                        }
                        if a[0] as! String != "Dangerous Liaisons" {
                            self._raise("ComplexDictionary - wrong first element in array")
                        }
                        if a[1] as! String != "Burn after reading" {
                            self._raise("ComplexDictionary - wrong second element in array")
                        }
                    } else {
                        self._raise("ComplexDictionary - wrong typed second element")
                    }
                    
                    if d.valueForKey("kids") as! Int != 2 {
                        self._raise("ComplexDictionary - wrong third pair")
                    }
                } else {
                    self._raise("ComplexDictionary - wrong type")
                }
            }
            
            bus.post("Ready")
        }
        
        if BaseController.isUsingWKWebView {
            Caravel.getDefault(self, wkWebView: getWKWebView(), draft: tuple.1!, whenReady: action)
        } else {
            Caravel.getDefault(self, webView: _webView, whenReady: action)
        }
        
        tuple.0()
    }
}