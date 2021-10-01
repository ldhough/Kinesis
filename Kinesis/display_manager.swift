//
//  display_manager.swift
//  Kinesis
//
//  Created by Lannie Hough on 9/30/21.
//

import Foundation

// If someone has more than 16 displays wtf?
fileprivate let MAX_DISPLAYS = 16

class DisplayManager {
    
    static var manager = DisplayManager()
    
    private init() {
        
    }
    
    public static func getDisplayListData() -> [DisplayData] {
        DisplayManager.getDisplayList().mapWithIndex({ idx, displayId in
            DisplayData(index: idx, frame: CGDisplayBounds(displayId))
        })
    }
    
    private static func getDisplayList() -> [CGDirectDisplayID] {

        let max:UInt32 = 16
        var displays = [CGDirectDisplayID](repeating: 0, count: Int(max))
        var onlineDisplaysCount:UInt32 = 0
        let err = CGGetOnlineDisplayList(max,
                                         &displays,
                                         &onlineDisplaysCount)
        
        if err != .success {
            log("Error getting list of online displays: \(err)")
            return []
        }
        
        return displays
        
    }
    
}
