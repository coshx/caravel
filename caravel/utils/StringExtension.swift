import Foundation

internal extension String {
    
    var length: Int {
        return self.characters.count
    }
    
    var first: String? {
        if self.length > 0 {
            return self[0]
        } else {
            return nil
        }
    }
    
    var last: String? {
        if self.length > 0 {
            return self[self.length - 1]
        } else {
            return nil
        }
    }
    
    subscript (i: Int) -> Character {
        return self[self.characters.index(self.startIndex, offsetBy: i)]
    }
    
    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }
    
    subscript (r: Range<Int>) -> String {
        return substring(with: (characters.index(startIndex, offsetBy: r.lowerBound) ..< characters.index(startIndex, offsetBy: r.upperBound)))
    }
}
