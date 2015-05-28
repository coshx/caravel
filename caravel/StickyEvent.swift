//
//  StickyEvent.swift
//  todolist
//
//  Created by Adrien on 24/05/15.
//  Copyright (c) 2015 test. All rights reserved.
//

import Foundation

internal class StickyEvent {
    internal var name: String
    internal var data: AnyObject?
    
    internal init(name: String) {
        self.name = name
    }
    
    internal convenience init(name: String, data: AnyObject) {
        self.init(name: name)
        
        self.data = data
    }
}