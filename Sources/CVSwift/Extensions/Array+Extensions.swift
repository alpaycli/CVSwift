//
//  Array+Extensions.swift
//  ItsukiAnalyzer
//
//  Created by Itsuki on 2024/08/11.
//

import SwiftUI

extension Array where Element: Hashable  {
    func sortBy(by sortOrder: [Int]) -> [Element]?{
        if self.count != sortOrder.count {
            return nil
        }
        var returningElements: [Element?] = [Element?](repeating: nil, count: self.count)
        for index in 0..<sortOrder.count {
            let sort = sortOrder[index]
            returningElements[index] = self[sort]
        }
        if returningElements.contains(where: {$0 == nil}) {
            return nil
        }
        return returningElements.map({$0!})
    }
    
    func difference(_ target: [Element]) -> [Element] {
        let thisSet = Set(self)
        let otherSet = Set(target)
        return Array(thisSet.symmetricDifference(otherSet))
    }

}
