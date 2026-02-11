//
//  Collection+Extensions.swift
//  ItsukiAnalyzer
//
//  Created by Itsuki on 2024/08/11.
//

import SwiftUI

extension Collection where Element: Comparable {
    func sortedIndices() -> [Int] {
        return enumerated()
            .sorted{ $0.element < $1.element }
            .map{ $0.offset }
    }
    
}
