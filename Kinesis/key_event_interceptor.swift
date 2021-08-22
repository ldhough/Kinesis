//
//  key_event_interceptor.swift
//  Kinesis
//
//  Created by Lannie Hough on 8/21/21.
//

import Foundation

// Should only be used as if is a member function of KeyEventInterceptor class
fileprivate func key_interceptor_callback(tapProxy: CGEventTapProxy,
                                          eventType: CGEventType,
                                          event: CGEvent,
                                          data: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    
    log("RECEIVED A KEY PRESS EVENT")
    let unmodifiedEvent = Unmanaged.passRetained(event)
    
    guard let interceptorData = data else {
        return unmodifiedEvent
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
        
        // Command + W has been pressed
        if code == interceptor.key.rawValue && event.flags.contains(.maskCommand) {
            interceptor.onPress()
            return nil
        }
        
    }
    
    return unmodifiedEvent
}

class KeyEventInterceptor: EventInterceptor {

    // Passed in and called on key / key combination press
    fileprivate let onPress:() -> Void
    fileprivate let key:Keycodes
    
    private var keyActions:[Keycodes:() -> Void] = [:]
    
    init(forKey: Keycodes, onPress: @escaping () -> Void) {
        self.key = forKey
        self.onPress = onPress
    }
    
    public func createKeyTap() {
        
        let self_ptr = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()) // void ptr to self
        let mask:CGEventMask = CGEventMask(1 << CGEventType.keyDown.rawValue) // Key down
        
        port = CGEvent.tapCreate(tap: CGEventTapLocation.cghidEventTap, // Tap at place where system events enter window server
                                 place: CGEventTapPlacement.headInsertEventTap, // Insert before other taps
                                 options: CGEventTapOptions.defaultTap, // Can modify events
                                 eventsOfInterest: mask,
                                 callback: key_interceptor_callback, // fn to run on event
                                 userInfo: self_ptr)
        
    }
    
}
