//
//  window_transformer.swift
//  Kinesis
//
//  Created by Lannie Hough on 8/21/21.
//

import Foundation
import AppKit

enum TransformerError: String, Error {
    
    case setPositionError = "Error setting position of window!"
    case setSizeError = "Error setting size of window!"
    case other = "Error with WindowTransformer!"
    
}

class WindowTransformer {
    
    private let windowElement:AXUIElement?
    
    init?(forWindowWithPid: pid_t) {
        
        // Make Accessibility object for given PID
        let accessApp:AXUIElement = AXUIElementCreateApplication(forWindowWithPid)
        
        // Get value associated with kAXWindowsAttribute in windowData, create windowElement from this data
        var windowData:AnyObject?
        // TODO: Use kAXFocusedWindowAttribute
        AXUIElementCopyAttributeValue(accessApp, kAXWindowsAttribute as CFString, &windowData)
        windowElement = (windowData as? [AXUIElement])?.first
        
        guard let _ = windowElement else { return nil }
        
    }
    
    public func transformWindowWithDeltas(x: CGFloat, y: CGFloat, forEvent: CGEvent) {
        let current = getCurrentWindowPosition(event: forEvent)
        guard let current = current else { return }
        let newX = current.x + x
        let newY = current.y + y
        do {
            try setPosition(to: CGPoint(x: newX, y: newY))
        } catch {
            print("CAUGHT ERROR IN TRANSFORMWINDOWWITHDELTAS")
        }
    }
    
    private static func getDisplayList() {
//        let screens = NSScreen.screens
//        print(screens)
//        for screen in screens {
//            print("= = = = = = = = = =")
//            let frame = screen.visibleFrame
//            print("Max X: \(frame.maxX)")
//            print("Max Y: \(frame.maxY)")
//            print("Min X: \(frame.minX)")
//            print("Min Y: \(frame.minY)")
//            let wholeFrame = screen.frame
//            print("Max X: \(wholeFrame.maxX)")
//            print("Max Y: \(wholeFrame.maxY)")
//            print("Min X: \(wholeFrame.minX)")
//            print("Min Y: \(wholeFrame.minY)")
//            //print(frame.)
//        }
//        print("* * * * * * * * * * *")
//        let ms = NSScreen.main!
//        let frame2 = ms.visibleFrame
//        print("Max X: \(frame2.maxX)")
//        print("Max Y: \(frame2.maxY)")
//        print("Min X: \(frame2.minX)")
//        print("Min Y: \(frame2.minY)")
//        let frame = ms.frame
//        print("Max X: \(frame.maxX)")
//        print("Max Y: \(frame.maxY)")
//        print("Min X: \(frame.minX)")
//        print("Min Y: \(frame.minY)")
        let max:UInt32 = 16
        var displays = Array<CGDirectDisplayID>(repeating: 0, count: Int(max))
        var onlineDisplaysCount:UInt32 = 0
        let err = CGGetOnlineDisplayList(max,
                                         &displays,
                                         &onlineDisplaysCount)
        
        if err != .success {
            log("Error getting list of online displays: \(err)")
        }
        
        for display in displays[0 ..< Int(onlineDisplaysCount)] {
            print(display)
            print(CGDisplayBounds(display))
        }
        
    }
    
    // Returns the index of screen 0 ... N the window is contained primarily within
    private static func withinScreenN(windowPoint: CGPoint) -> Int {
        
        // Arbitrary but like who has more than 16 displays?
        let maxDisplays:UInt32 = 16
        var onlineDisplays = [CGDirectDisplayID](repeating: 0, count: Int(maxDisplays))
        var onlineDisplaysCount:UInt32 = 0
        
        let err = CGGetOnlineDisplayList(maxDisplays, &onlineDisplays, &onlineDisplaysCount)
        
        if err != .success {
            log("Error getting list of online displays: \(err)")
        }
        
        for i in 0 ..< Int(onlineDisplaysCount) {
            
            let displayId = onlineDisplays[i]
            let displayBounds = CGDisplayBounds(displayId)
            let windowInsideDisplay = NSPointInRect(windowPoint, displayBounds)
            
            if windowInsideDisplay {
                return i
            }
            
        }
        
        return -1
//        let screens = NSScreen.screens
//
//        for i in 0 ..< screens.count {
//            let screenFrame = screens[i].frame
//            let windowInside = NSPointInRect(windowPoint, screenFrame)
//            if windowInside {
//                return i
//            }
//        }
//
//        return -1
    }
    
    private func getCurrentWindowSize() -> CGSize? {
        if windowElement == nil { return nil }
        var sizeData:CFTypeRef?
        AXUIElementCopyAttributeValue(windowElement!, kAXSizeAttribute as CFString, &sizeData)
        let currentSize = axValueAsCGSize(sizeData! as! AXValue)
        return currentSize
    }
    
    private func getCurrentWindowPosition(event: CGEvent) -> CGPoint? {

        //WindowTransformer.getDisplayList()
        
        if windowElement == nil { return nil }
        
        var positionData:CFTypeRef?
        AXUIElementCopyAttributeValue(windowElement!,
                                      kAXPositionAttribute as CFString,
                                      &positionData)
                
        let currentPos = axValueAsCGPoint(positionData! as! AXValue)
        
        //print(currentPos)
        print(WindowTransformer.withinScreenN(windowPoint: currentPos))
        //print(NSScreen.main)
        
        return currentPos
    }
    
    public func setPositionAndSize(_ toPosition: CGPoint, _ toSize: CGSize) throws {

        try setPosition(to: toPosition)
        try setSize(to: toSize)
        
    }
    
    
    public func setPosition(to: CGPoint) throws {
        
        var newPoint = to
        let position:CFTypeRef? = AXValueCreate(AXValueType(rawValue: kAXValueCGPointType)!, &newPoint)
        if position == nil {
            throw TransformerError.setPositionError
        }
        AXUIElementSetAttributeValue(windowElement!, kAXPositionAttribute as CFString, position!)
    
    }
    
    public func setSize(to: CGSize) throws {
        
        var newSize = to
        let size:CFTypeRef? = AXValueCreate(AXValueType(rawValue: kAXValueCGSizeType)!, &newSize)
        if size == nil {
            throw TransformerError.setSizeError
        }
        AXUIElementSetAttributeValue(windowElement!, kAXSizeAttribute as CFString, size!)
        //let x = kAXColorWellRole
    }
    
    
}


//        var currentScreen:NSScreen?
//        let mouseLoc:NSPoint = event.location
//        let screens:[NSScreen] = NSScreen.screens
//        var screenWithMouseFound = false
//        var i = 0
//        while !screenWithMouseFound {
//            let screen = screens[i]
//            if NSMouseInRect(mouseLoc, screen.frame, false) {
//                currentScreen = screen
//                screenWithMouseFound = true
//            }
//            i += 1
//        }
//        print(currentScreen)

/*
 Check which screen the window is currently in
 */
//        var currentScreen:NSScreen?
//        let windowLoc:NSPoint = currentPos
//        let screens:[NSScreen] = NSScreen.screens
//        var screenWithMouseFound = false
//        var i = 0
//        while !screenWithMouseFound {
//            let screen = screens[i]
//            if NSPointInRect(windowLoc, screen.frame) {
//                currentScreen = screen
//                screenWithMouseFound = true
//            }
//            i += 1
//        }
//        print(currentScreen)
