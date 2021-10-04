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
    public let pid:pid_t
    
    init?(forWindowWithPid: pid_t) {
        
        self.pid = forWindowWithPid
        
        // Make Accessibility object for given PID
        let accessApp:AXUIElement = AXUIElementCreateApplication(forWindowWithPid)
        
        // Get value associated with kAXWindowsAttribute in windowData, create windowElement from this data
        var windowData:AnyObject?
        // TODO: Use kAXFocusedWindowAttribute
        // AXUIElementCopyAttributeValue(accessApp, kAXFocusedWindowAttribute as CFString, &windowData)
        AXUIElementCopyAttributeValue(accessApp, kAXWindowsAttribute as CFString, &windowData)
        windowElement = (windowData as? [AXUIElement])?.first
        
        guard let _ = windowElement else { return nil }

        
    }
    
    // Returns the point that the window got moved to
    public func transformWindowWithDeltas(x: CGFloat, y: CGFloat, forEvent: CGEvent) {
        guard let current = getCurrentWindowPosition() else { return }
        let newX = current.x + x
        let newY = current.y + y

        do {
            try setPosition(to: CGPoint(x: newX, y: newY))
        } catch {
            log("Error in transformWindowWithDeltas")
        }
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

        // TODO: Make this safer
        let currentPos = axValueAsCGPoint(positionData! as! AXValue)
        return currentPos
    }
    
    public func setPositionAndSize(_ toPosition: CGPoint, _ toSize: CGSize) throws {
        try setPosition(to: toPosition)
        try setSize(to: CGSize(width: 1.0, height: 1.0)) // hack
        try setSize(to: toSize)
    }
    
    public func setPositionAndSize(_ toRect: CGRect) throws {
        print("TRY SET SIZE TO WIDTH: \(toRect.size.width)")
//        try setSize(to: toRect.size)
        try setPosition(to: toRect.origin)
        /*
         This might be the stupidest hack ever but it
         somehow prevents weird size conflict behavior
         in the library
         */
        try setSize(to: CGSize(width: 1.0, height: 1.0)) // hack
        try setPosition(to: toRect.origin) // more hack
        try setSize(to: toRect.size) // intended size
        print("ACTUAL SET WIDTH IS: \(getCurrentWindowSize()?.width)")
    }
    
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
        print("SIZE: \(size)")
        let err = AXUIElementSetAttributeValue(windowElement!, kAXSizeAttribute as CFString, size!)
        if err != .success {
            print("AXError resizing window \(err)")
        }
    }
    
}
