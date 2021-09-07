//
//  utils.swift
//  Kinesis
//
//  Created by Lannie Hough on 8/21/21.
//

import Foundation

@inline(__always) func axValueAsCGPoint(_ value: AXValue) -> CGPoint {
    var point = CGPoint.zero
    AXValueGetValue(value, AXValueType.cgPoint, &point)
    return point
}

@inline(__always) func axValueAsCGSize(_ value: AXValue) -> CGSize {
    var size = CGSize.zero
    AXValueGetValue(value, AXValueType.cgSize, &size)
    return size
}

func log(_ msg: String) {
    print(msg)
}

infix operator &&=
@inline(__always) func &&=(lhs: inout Bool, rhs: Bool) {
    lhs = lhs && rhs
}

func doAndReturn<T>(toReturn: inout T, action: () -> Void) -> T {
    action()
    return toReturn
}

extension Int64 {
    
    // Compares a keycode represented as Int64 to Keycode enum value
    func equals(_ code: Keycodes) -> Bool {
        return self == code.rawValue
    }
    
}

func currentTimeInMilliSeconds() -> Int {
    let currentDate = Date()
    let since1970 = currentDate.timeIntervalSince1970
    return Int(since1970 * 1000)
}

extension Array {
    
    func mapWithIndex<T>(_ with: (Int, Element) -> T) -> [T] {
        var new:[T] = []
        for i in 0 ..< self.count {
            let element = self[i]
            new.append(with(i, element))
        }
        return new
    }
    
}
