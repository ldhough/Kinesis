//
//  window_transformer.swift
//  Kinesis
//
//  Created by Lannie Hough on 8/21/21.
//

import Foundation

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
    
    public func transformWindowWithDeltas(x: CGFloat, y: CGFloat) {
        let current = getCurrentWindowPosition()
        guard let current = current else { return }
        let newX = current.x + x
        let newY = current.y + y
        do {
            try setPosition(to: CGPoint(x: newX, y: newY))
        } catch {
            
        }
    }
    
    private func getCurrentWindowPosition() -> CGPoint? {
        
        if windowElement == nil { return nil }
        
        var positionData:CFTypeRef?
        AXUIElementCopyAttributeValue(windowElement!,
                                      kAXPositionAttribute as CFString,
                                      &positionData)
                
        let currentPos = axValueAsCGPoint(positionData! as! AXValue)
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
        
    }
    
    
}
