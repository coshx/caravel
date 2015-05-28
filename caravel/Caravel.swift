//
//  Bus.swift
//  todolist
//
//  Created by Adrien on 23/05/15.
//  Copyright (c) 2015 test. All rights reserved.
//

import Foundation
import UIKit

public class Caravel: NSObject, UIWebViewDelegate {
    private enum SupportedType {
        case Bool, Int, Double, Float, String, Array, Dictionary
    }
    
    private static var _default: Caravel?
    private static var _buses: [Caravel] = [Caravel]()
    
    private var _name: String
    private var _isInitialized: Bool
    private lazy var _subscribers: [CaravelSubscriber] = [CaravelSubscriber]()
    private lazy var _initializers: [(Caravel) -> Void] = Array<(Caravel) -> Void>()
    private var _webView: UIWebView
    
    public var name: String {
        return _name
    }
    
    private init(name: String, webView: UIWebView) {
        self._name = name
        self._isInitialized = false
        self._webView = webView
        
        super.init()
        
        UIWebViewDelegateMediator(webView: self._webView, secondDelegate: self)
    }
    
    private func _serialize(input: AnyObject, type: SupportedType) -> String {
        var output: String?
        
        switch (type) {
        case .Bool:
            var b = input as! Bool
            output = b ? "true" : "false"
        case .Int:
            var i = input as! Int
            output = "\(i)"
        case .Double:
            var d = input as! Double
            output = "\(d)"
        case .Float:
            var f = input as! Float
            output = "\(f)"
        case .String:
            var s = input as! String
            output = "\"\(s)\""
        case .Array, .Dictionary:
            var json = NSJSONSerialization.dataWithJSONObject(input, options: NSJSONWritingOptions(), error: NSErrorPointer())!
            var s = NSString(data: json, encoding: NSUTF8StringEncoding)!
            output = s as String
        }
        
        return output!
    }

    private func _post(eventName: String, eventData: AnyObject?, type: SupportedType?) {
        var toRun: String?
        var data: String?
        
        if let d: AnyObject = eventData {
            data = _serialize(d, type: type!)
        } else {
            data = "null"
        }
        
        if _name == "default" {
            toRun = "Caravel.getDefault().raise(\"\(eventName)\", \(data!))"
        } else {
            toRun = "Caravel.get(\"\(_name)\").raise(\"\(eventName)\", \(data!))"
        }
        
        self._webView.stringByEvaluatingJavaScriptFromString(toRun!)
    }
    
    private func _parseArgs(input: String) -> [String] {
        var outcome = [String]()
        var prev: Character?
        var buffer = String()
        
        for current in input {
            if current == "@" && prev != nil && prev != "\\" {
                outcome.append(buffer)
                buffer = ""
            } else {
                buffer.append(current)
            }
            
            prev = current
        }
        
        outcome.append(buffer)
        
        return outcome
    }
    
    private func _escapeArg(arg: String) -> String {
        return arg.stringByReplacingOccurrencesOfString("\\@", withString: "@", options: .CaseInsensitiveSearch, range: nil)
    }
    
    public func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if let lastPathComponent: String = request.URL?.lastPathComponent {
            if count(lastPathComponent) > count("caravel") && (lastPathComponent as NSString).substringToIndex(count("caravel")) == "caravel" {
                var args = _parseArgs(lastPathComponent)
                var busName = _escapeArg(args[1])
                var eventName = _escapeArg(args[2])
                
                if _name == busName {
                    if eventName == "CaravelInit" {
                        _isInitialized = true
                        for i in _initializers {
                            i(self)
                        }
                    } else {
                        var eventData: AnyObject?
                        
                        if args.count > 3 {
                            eventData = _escapeArg(args[3])
                        } else {
                            eventData = nil
                        }
                        
                        for s in _subscribers {
                            if s.name == eventName {
                                s.callback(eventName, eventData)
                            }
                        }
                    }
                }
                    
                return false
            }
            
            return true
        }
        
        return true
    }
    
    public func whenReady(callback: (Caravel) -> Void) {
        if _isInitialized {
            callback(self)
        } else {
            _initializers.append(callback)
        }
    }
    
    public func post(eventName: String) {
        _post(eventName, eventData: nil, type: nil)
    }
    
    public func post(eventName: String, anInt: Int) {
        _post(eventName, eventData: anInt, type: .Int)
    }
    
    public func post(eventName: String, aBool: Bool) {
        _post(eventName, eventData: aBool, type: .Bool)
    }
    
    public func post(eventName: String, aDouble: Double) {
        _post(eventName, eventData: aDouble, type: .Double)
    }
    
    public func post(eventName: String, aFloat: Float) {
        _post(eventName, eventData: aFloat, type: .Double)
    }
    
    public func post(eventName: String, anArray: NSArray) {
        _post(eventName, eventData: anArray, type: .Array)
    }
    
    public func post(eventName: String, aDictionary: NSDictionary) {
        _post(eventName, eventData: aDictionary, type: .Dictionary)
    }
    
    public func register(eventName: String, callback: (String, AnyObject?) -> Void) {
        _subscribers.append(CaravelSubscriber(name: eventName, callback: callback))
    }
    
    public static func getDefault(webView: UIWebView) -> Caravel {
        if let d = _default {
            return d
        } else {
            _default = Caravel(name: "default", webView: webView)
            return _default!
        }
    }
    
    public static func get(name: String, webView: UIWebView) -> Caravel {
        if name == "default" {
            return getDefault(webView)
        } else {
            var newBus: Caravel?
            
            for b in _buses {
                if b.name == name {
                    return b
                }
            }
            
            newBus = Caravel(name: name, webView: webView)
            _buses.append(newBus!)
            return newBus!
        }
    }
}