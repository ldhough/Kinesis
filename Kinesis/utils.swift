//
//  utils.swift
//  Kinesis
//
//  Created by Lannie Hough on 8/21/21.
//

import Foundation

func log(_ msg: String) {
    print(msg)
}

infix operator &&=
@inline(__always) func &&=(lhs: inout Bool, rhs: Bool) {
    lhs = lhs && rhs
}
