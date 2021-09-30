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
//        AXUIElementCopyAttributeValue(accessApp, kAXFocusedWindowAttribute as CFString, &windowData)
        windowElement = (windowData as? [AXUIElement])?.first
        
        guard let _ = windowElement else { return nil }

        
    }
    
    // Returns the point that the window got moved to
    public func transformWindowWithDeltas(x: CGFloat, y: CGFloat, forEvent: CGEvent) {
        let current = getCurrentWindowPosition()
        guard let current = current else { return }
        let newX = current.x + x
        let newY = current.y + y

        do {
            try setPosition(to: CGPoint(x: newX, y: newY))
        } catch {
            log("Error in transformWindowWithDeltas")
        }
    }
    
    // Returns the index of screen 0 ... N the window is contained primarily within
    private static func withinScreenN(windowPoint: CGPoint) -> DisplayData? {
        
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
                return DisplayData(index: i, frame: displayBounds)
            }
            
        }
        
        // TODO: If outside visible bounds (left of leftmost display),
        // possibly return closest display instead of -1?
        
        return nil
    }
    
    public func getCurrentWindowSize() -> CGSize? {
        if windowElement == nil { return nil }
        var sizeData:CFTypeRef?
        AXUIElementCopyAttributeValue(windowElement!, kAXSizeAttribute as CFString, &sizeData)
        let currentSize = axValueAsCGSize(sizeData! as! AXValue)
        return currentSize
    }
    
    public func getCurrentWindowPosition() -> CGPoint? {
        
        if windowElement == nil { return nil }
        
        var positionData:CFTypeRef?

        AXUIElementCopyAttributeValue(windowElement!,
                                      kAXPositionAttribute as CFString,
                                      &positionData)
                
        let currentPos = axValueAsCGPoint(positionData! as! AXValue)
        
        let display = WindowTransformer.withinScreenN(windowPoint: currentPos)
                
        return currentPos
    }
    
    public func setPositionAndSize(_ toPosition: CGPoint, _ toSize: CGSize) throws {

        try setPosition(to: toPosition)
        try setSize(to: toSize)
        
    }
    
    var lastFinished = true
    
    public func setPosition(to: CGPoint) throws {
        
        var newPoint = to
        let position:CFTypeRef? = AXValueCreate(AXValueType(rawValue: kAXValueCGPointType)!, &newPoint)
        if position == nil {
            throw TransformerError.setPositionError
        }
        let err = AXUIElementSetAttributeValue(self.windowElement!, kAXPositionAttribute as CFString, position!)

        guard err == .success else {
            log("AXError moving window \(err.rawValue)")
            throw TransformerError.setPositionError
        }

    }
    
    public func setSize(to: CGSize) throws {
        
        var newSize = to
        let size:CFTypeRef? = AXValueCreate(AXValueType(rawValue: kAXValueCGSizeType)!, &newSize)
        if size == nil {
            throw TransformerError.setSizeError
        }
        let err = AXUIElementSetAttributeValue(windowElement!, kAXSizeAttribute as CFString, size!)
        if err != .success {
            print("AXError resizing window \(err)")
        }
    }
    
}
