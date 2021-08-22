//
//  window_manager.swift
//  Kinesis
//
//  Created by Lannie Hough on 8/22/21.
//

import Foundation
import AppKit

enum WindowManagerError: String, Error {
    case other = "Window manager error!"
}

class KinesisWindowManager {
    
    private let pidObserver:PidObserver
    private var transformer:WindowTransformer?
    private var listeningEscapeAndMouseFlag = false
    
    private var keyInterceptor:KeyEventInterceptor?
    private var mouseInterceptor:MouseEventInterceptor?
    
    private var activePid:pid_t?
    
    init() {
        self.pidObserver = PidObserver()
        self.keyInterceptor = KeyEventInterceptor(keyEventAction: self.keyEventAction)
        self.mouseInterceptor = MouseEventInterceptor(mouseEventAction: self.mouseEventAction)
    }
    
    // Activates the window manager, returns true if successful, false if not
    public func start() -> Bool {
        
        guard let keyInterceptor = keyInterceptor, let mouseInterceptor = mouseInterceptor else {
            return false
        }
        
        keyInterceptor.createKeyTap()
        keyInterceptor.activateTap()
        
        mouseInterceptor.createMouseTap()
        mouseInterceptor.activateTap()
        
        pidObserver.observeActivePid({ pid in

            self.activePid = pid

        })
        
        return true
    }
    
    /*
     Describes the behavior of the window manager on a key pressed event.
     Passed to and called from keyInterceptor:KeyEventInterceptor object.
     */
    private func keyEventAction(event: CGEvent) -> Unmanaged<CGEvent>? {
        let unmodifiedEvent = Unmanaged.passRetained(event)
        let code = event.getIntegerValueField(.keyboardEventKeycode)
        
        // Command + W has been pressed
        if code == Keycodes.w.rawValue && event.flags.contains(.maskCommand) {
            
            self.listeningEscapeAndMouseFlag = true
            return nil
        
        // Escape has been pressed while in window management mode
        } else if code == Keycodes.esc.rawValue && self.listeningEscapeAndMouseFlag {
            
            self.listeningEscapeAndMouseFlag = false
            self.transformer = nil
            return nil
        // Something this program does not care about happens
        } else {
            return unmodifiedEvent
        }
    }
    
    /*
     Describes the behavior of the window manager on a mouse moved event.
     Passed to and called from mouseInterceptor:MouseEventInterceptor object.
     */
    private func mouseEventAction(event: CGEvent) -> Unmanaged<CGEvent>? {
        let unmodifiedEvent = Unmanaged.passRetained(event)
        
        if !listeningEscapeAndMouseFlag {
            return unmodifiedEvent
        }
                
        guard let activePid = activePid else { return unmodifiedEvent }
        
        if let _ = transformer {} else {
            transformer = WindowTransformer(forWindowWithPid: activePid)
        }
        
        let eventLocation = event.location

        let deltaEvent = NSEvent.init(cgEvent: event)
        let deltaX = deltaEvent?.deltaX
        let deltaY = deltaEvent?.deltaY
        
        guard let deltaX = deltaX, let deltaY = deltaY else { return nil }
        
        // Attempt to move window based on mouse events
        transformer?.transformWindowWithDeltas(x: deltaX, y: deltaY)
        
        CGWarpMouseCursorPosition(eventLocation) // Don't move cursor
        
        return nil
    }
    
}
