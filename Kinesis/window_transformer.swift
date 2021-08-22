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
        AXUIElementCopyAttributeValue(accessApp, kAXWindowsAttribute as CFString, &windowData)
        windowElement = (windowData as? [AXUIElement])?.first
        
        guard let _ = windowElement else { return nil }
        
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
