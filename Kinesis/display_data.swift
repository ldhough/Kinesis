//
//  display_data.swift
//  Kinesis
//
//  Created by Lannie Hough on 8/30/21.
//

import Foundation

struct DisplayData {
    
    init(index: Int = 0, from: CGDirectDisplayID) {
        self.index = index
        self.frame = CGDisplayBounds(from)
    }
    
    init(index: Int = 0, frame: CGRect) {
        self.index = index
        self.frame = frame
    }
    
    let index:Int
    let frame:CGRect
    
    var size:CGSize {
        frame.size
    }
    
    var origin:CGPoint {
        frame.origin
    }
    
}
