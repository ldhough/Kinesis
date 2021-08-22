//
//  mouse_event_interceptor.swift
//  Kinesis
//
//  Created by Lannie Hough on 8/22/21.
//

import Foundation

// Should only be used as if is a member function of MouseEventInterceptor class
fileprivate func mouse_interceptor_callback(tapProxy: CGEventTapProxy,
                                            eventType: CGEventType,
                                            event: CGEvent,
                                            data: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    
    log("RECEIVED A MOUSE EVENT")
    let unmodifiedEvent = Unmanaged.passRetained(event)
    
    guard let interceptorData = data else {
        return unmodifiedEvent
    }
    
    if eventType != .mouseMoved {
        return unmodifiedEvent
    }
    
    let interceptor = Unmanaged<MouseEventInterceptor>
        .fromOpaque(interceptorData)
        .takeUnretainedValue()
    
    return interceptor.mouseEventAction(event)
}

class MouseEventInterceptor: EventInterceptor {
    
    // Passed in and called on mouse event action
    fileprivate var mouseEventAction:(CGEvent) -> Unmanaged<CGEvent>?
    
    init(mouseEventAction: @escaping (CGEvent) -> Unmanaged<CGEvent>?) {
        self.mouseEventAction = mouseEventAction
    }
    
    public func setMouseEventAction(to: @escaping (CGEvent) -> Unmanaged<CGEvent>?) {
        mouseEventAction = to
    }
    
    public func createMouseTap() {
        let self_ptr = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()) // void ptr to self
        let mask:CGEventMask = CGEventMask(1 << CGEventType.mouseMoved.rawValue) // Mouse event
    
        port = CGEvent.tapCreate(tap: CGEventTapLocation.cghidEventTap, // Tap at place where system events enter window server
                                 place: CGEventTapPlacement.headInsertEventTap, // Insert before other taps
                                 options: CGEventTapOptions.defaultTap, // Can modify events
                                 eventsOfInterest: mask,
                                 callback: mouse_interceptor_callback, // fn to run on event
                                 userInfo: self_ptr)
    }
    
}
