//
//  display_manager.swift
//  Kinesis
//
//  Created by Lannie Hough on 9/30/21.
//

import Foundation

// If someone has more than 16 displays wtf?
fileprivate let MAX_DISPLAYS:UInt32 = 16

class DisplayLayout {
    
    init () {}
    
    private let displayVerticalSegments = 2
    private let displayHorizontalSegments = 2
    
    private var mainDisplayIndex = 0
    
    private var layout:[[CGRect?]] = []
    private var layoutHorizontalCount:Int {
        self.layout[0].count
    }
    private var layoutVerticalCount:Int {
        self.layout.count
    }
    
    public func createLayout(displays: [DisplayData]) {
        for display in displays {
            // Check top
            
            // Check right
            // Check bottom
            // Check left
        }
    }
    
}

class DisplayManager {
    
    static var manager = DisplayManager()
    
    var layout:DisplayLayout
    
    private init() {
        self.layout = DisplayLayout()
    }
    
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
     Returns DisplayData struct that represents the display with the longest edge to
     the right of the DisplayData struct passed to the function
     */
    private static func getNextRightDisplay(ofDisplay: DisplayData) -> DisplayData? {
        
        let displays = getDisplayListData()
        
        var rightmost:DisplayData?
        var rightmostOverlap:CGFloat?
        
        let topOrigin = ofDisplay.origin.y
        let bottomOrigin = ofDisplay.origin.y + ofDisplay.size.height
        
        for display in displays {
            if display.index == ofDisplay.index { // Same display
                continue
            }
            // Right side of original display lines up with left side of compared display
            if display.origin.x == ofDisplay.origin.x + ofDisplay.size.width {
                if let _ = rightmost {
                    // Identify how much overlap the display being checked has against ofDisplay
                    
                    let topComparedDisplay = display.origin.y
                    let bottomComparedDisplay = display.origin.y + display.size.height
                    
                    let topIntersect =
                    
                    let overlap = bottomCtopComparedDisplay -
                } else {
                    rightmost = display
                }
            }
        }
        return nil
    }
    
    private struct Line {
        let start:CGFloat
        let end:CGFloat
    }
    
    /*
     Given two parallel lines represented by start and end points where
     start point < end point, find the length of the shared distance
     that they traverse.
     ex:
     ______
       ___
     overlap is 3
     ---
      ---
     overlap is 2
     ---
        ---
     overlap is 0
     ---
          ---
     */
    private static func lineOverlap(l1Start: CGFloat, l1End: CGFloat,
                                    l2Start: CGFloat, l2End: CGFloat) -> CGFloat {
        if l1Start <= l2Start {
            let overlap = l1End - l2Start
            return overlap < 0.0 ? 0.0 : overlap
        } else {
            
        }
        
        return 0.0
    }
    
}
