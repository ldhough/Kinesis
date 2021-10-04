//
//  display_manager.swift
//  Kinesis
//
//  Created by Lannie Hough on 9/30/21.
//

import Foundation

// If someone has more than 16 displays wtf?
fileprivate let MAX_DISPLAYS:UInt32 = 16

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

//class DisplayLayout {
//
//    init () {}
//
//    var right:DisplayLayout?
//    var left: DisplayLayout?
//    var top:DisplayLayout?
//    var bottom:DisplayLayout?
//
//}

class DisplayManager {
    
    static var manager = DisplayManager()
    
    
    private init() {}
    
    public static func getDisplayListData() -> [DisplayData] {
        DisplayManager.getDisplayList().mapWithIndex({ idx, displayId in
            DisplayData(index: idx, frame: CGDisplayBounds(displayId))
        })
    }
    
    private static func getDisplayList() -> [CGDirectDisplayID] {

        var displays = [CGDirectDisplayID](repeating: 0, count: Int(MAX_DISPLAYS))
        var onlineDisplaysCount:UInt32 = 0
        let err = CGGetOnlineDisplayList(MAX_DISPLAYS,
                                         &displays,
                                         &onlineDisplaysCount)
        print(onlineDisplaysCount)
        if err != .success {
            log("Error getting list of online displays: \(err)")
            return []
        }
        
        return Array<CGDirectDisplayID>(displays.prefix(upTo: Int(onlineDisplaysCount)))
        
    }
    
    
    /*
     Finds and returns a DisplayData struct represting a display, from a list built of all
     active displays, that is "most adjacent" (shares the longest edge) to the display passed
     in on the side of whatever direction is indicated by the Direction struct passed in
     */
    public static func getAdjacentDisplay(to: Direction, sourceDisplay: DisplayData) -> DisplayData? {
        
        // Get representations of all displays
        let displays = getDisplayListData()
        
        // Store whichever display that has been checked yet has the longest shared edge
        var currentMostOverlapDisplay:DisplayData?
        var currentMostOverlap:CGFloat?
        
        let sourceDisplayBorder:RealLine
        
        /*
         Checks whether two displays line up (even if they may have no overlap), computed
         differently depending on whether we are checking a horizontal or vertical edge
         */
        let linesUpWith:(DisplayData) -> Bool
        /*
         Creates a representation of a display edge - we know the edges of compared displays
         will be colinear so we don't have to use a two-dimensional line, we do need to know
         whether to use the horizontal or vertical dimensions of the display to achieve this
         */
        let createLine:(DisplayData) -> RealLine
        
        switch to {
        case .right, .left:
            print("r, l")
            sourceDisplayBorder = RealLine(start: sourceDisplay.origin.y,
                                           end: sourceDisplay.origin.y + sourceDisplay.size.height)
            if to == .right {
                linesUpWith = { display in
                    display.origin.x == sourceDisplay.origin.x + sourceDisplay.size.width
                }
            } else {
                linesUpWith = { display in
                    sourceDisplay.origin.x == display.origin.x + display.size.width
                }
            }
            createLine = { display in
                RealLine(start: display.origin.y, end: display.origin.y + display.size.height)
            }
        case .top, .bottom:
            sourceDisplayBorder = RealLine(start: sourceDisplay.origin.x,
                                           end: sourceDisplay.origin.x + sourceDisplay.size.width)
            linesUpWith = { display in
                display.origin.y == sourceDisplay.origin.y + sourceDisplay.size.height
            }
            createLine = { display in
                RealLine(start: display.origin.x, end: display.origin.x + display.size.width)
            }
        }
        
        for display in displays where display.index != sourceDisplay.index { // Don't compare source display to itself
            
            // Verify that top/bottom or right/left of two displays line up (not necessarily adjacent)
            if linesUpWith(display) {
                print("DOES LINE UP")
                /*
                 Identify how much overlap the display being checked has against the source display,
                 if indeed it has any at all
                 */
                
                let comparedBorder = createLine(display)
                let displayBorderOverlapLine = sourceDisplayBorder.overlap(with: comparedBorder)
                
                guard let displayBorderOverlap = displayBorderOverlapLine?.distance else {
                    // No overlap
                    continue
                }
                
                if let _ = currentMostOverlapDisplay, let cmo = currentMostOverlap {
                
                    if displayBorderOverlap > cmo {
                        currentMostOverlapDisplay = display
                        currentMostOverlap = displayBorderOverlap
                    }
                } else {
                    currentMostOverlapDisplay = display
                    currentMostOverlap = displayBorderOverlap
                }
            }
        }
        
        return currentMostOverlapDisplay
    }
    
}
