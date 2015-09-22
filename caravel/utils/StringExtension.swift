//
//  StringExtension.swift
//  Caravel
//
//  Created by Adrien on 19/06/15.
//  Copyright (c) 2015 Coshx Labs. All rights reserved.
//

import Foundation

internal extension String {
    subscript (i: Int) -> Character {
        return self[self.startIndex.advancedBy(i)]
    }
    
    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }
    
    subscript (r: Range<Int>) -> String {
        return substringWithRange(Range(start: startIndex.advancedBy(r.startIndex), end: startIndex.advancedBy(r.endIndex)))
    }
}
