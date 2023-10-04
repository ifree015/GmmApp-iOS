//
//  CoreFoundationExtension.swift
//  GmmApp
//
//  Created by GwangHyeok Yu on 2023/09/25.
//

/// reference: https://tngusmiso.tistory.com/46
extension String {
    
    subscript(_ index: Int) -> Character {
        return self[self.index(self.startIndex, offsetBy: index)]
    }
    
    subscript(_ range: Range<Int>) -> String {
        let fromIndex = self.index(self.startIndex, offsetBy: range.startIndex)
        let toIndex = self.index(self.startIndex, offsetBy: range.endIndex)
        return String(self[fromIndex..<toIndex])
    }
}
