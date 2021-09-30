//
//  keycodes.swift
//  Kinesis
//
//  Created by Lannie Hough on 8/21/21.
//

enum Keycodes: Int {
    
    case esc = 53
    
    case w = 13
    case command = 55
    
    case left  = 123; case h = 4
    case right = 124; case l = 37
    case down  = 125; case j = 38
    case up    = 126; case k = 40
    
    case invalid = -1
}

let DIRECTION_KEYCODES:Set<Keycodes> = [.left, .right, .down, .up, .h, .l, .j, .k]
