//
//  key_event_interceptor.swift
//  Kinesis
//
//  Created by Lannie Hough on 8/21/21.
//

import Foundation

fileprivate func interceptor_callback(tapProxy: CGEventTapProxy,
                          eventType: CGEventType,
                          event: CGEvent,
                          data: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    
    log("RECEIVED A KEY PRESS EVENT")
    
    guard let interceptorData = data else {
        return nil
    }
    
    /*
     Because instance callback or properties can't be used in CGEvent.tapCreate,
     pass a void ptr to self to the callback and turn it back into an ordinary
     KeyEventInterceptor object
     */
    
    let interceptor = Unmanaged<KeyEventInterceptor>
        .fromOpaque(interceptorData)
        .takeUnretainedValue()
    
    if eventType == .keyDown {
        let code = event.getIntegerValueField(.keyboardEventKeycode)
        if code == Keycodes.down.rawValue {
            log("COMMAND PRESSED")
        }
    }
    
    return nil
}

class KeyEventInterceptor {
    
    var port:CFMachPort?
    
    public func tapIsEnabled() -> Bool {
        return CGEvent.tapIsEnabled(tap: port!)
    }
    
    public func activateKeyTap() {
        CGEvent.tapEnable(tap: port!, enable: true)
        let runLoopSrc = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, port, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSrc, .commonModes)
    }
    
    public func createKeyTap() {
        
        let self_ptr = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()) // void ptr to self
        let mask:CGEventMask = CGEventMask(1 << CGEventType.keyDown.rawValue) // Key down
        port = CGEvent.tapCreate(tap: CGEventTapLocation.cghidEventTap, // Tap at place where system events enter window server
                                 place: CGEventTapPlacement.headInsertEventTap, // Insert before other taps
                                 options: CGEventTapOptions.defaultTap, // Can modify events
                                 eventsOfInterest: mask,
                                 callback: interceptor_callback, // fn to run on event
                                 userInfo: self_ptr)
        
    }
    
}
