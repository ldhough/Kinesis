//
//  event_interceptor.swift
//  Kinesis
//
//  Created by Lannie Hough on 8/22/21.
//

import Foundation

class EventInterceptor {

    public var port:CFMachPort?
    
    // Check if listening for key press events
    public func tapIsEnabled() -> Bool {
        guard let port = port else { return false }
        return CGEvent.tapIsEnabled(tap: port)
    }
    
    // Activate listening for key press events
    public func activateTap() {
        guard let port = port else { return }
        CGEvent.tapEnable(tap: port, enable: true)
        let runLoopSrc = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, port, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSrc, .commonModes)
    }
    
    // Stop listening for key press event
    public func disableTap() {
        guard let port = port else { return }
        CGEvent.tapEnable(tap: port, enable: false)
    }
    
    deinit {
        disableTap()
        log("EventInterceptor: Disabling event tap!")
    }
    
}
