//
//  StringExtension.swift
//  Caravel
//
//  Created by Adrien on 19/06/15.
//  Copyright (c) 2015 Coshx Labs. All rights reserved.
//

import Foundation

extension String {
    subscript (i: Int) -> Character {
        return self[advance(self.startIndex, i)]
    }
    
    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }
}