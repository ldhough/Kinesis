//
//  line.swift
//  Kinesis
//
//  Created by Lannie Hough on 10/3/21.
//

import Foundation

// Represents distance w/ start and end points on a 1D number line
struct RealLine {
    
    let start:CGFloat
    let end:CGFloat
    
    var distance:CGFloat {
        end - start
    }
    
    // Returns the overlap between two 1D lines as a line, or nil if none exists
    func overlap(with: RealLine) -> RealLine? {
        
        /*
         If the start of the second line is inside the first line, there is overlap, this
         overlap will be the distance from the start of the second line, to the end of
         whichever line comes first
         */
        if self.start <= with.start {
            return with.start < self.end ? RealLine(start: with.start, end: min(self.end, with.end)) : nil
        } else {
            return self.start < with.end ? RealLine(start: self.start, end: min(with.end, self.end)) : nil
        }
        
    }
}
