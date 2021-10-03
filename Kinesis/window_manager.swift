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

/*
 Class describes how windows behave in response to certain mouse and key events
 */

class KinesisWindowManager {
    
    // Dependencies
    private let pidObserver:PidObserver
    private var transformer:WindowTransformer?
    private var keyInterceptor:KeyEventInterceptor?
    private var mouseInterceptor:MouseEventInterceptor?
    
    // Logic management properties
    private var listeningEscapeAndMouseFlag = false
    private var activePid:pid_t?
    private var lastWindowRect:CGRect?
    
    /*
     Window position updates from cursor events happen extremely rapidly.  When multiple
     displays are active, updates can take long enough to cause inconsistent and sluggish
     window updates that may eventually kill the event interceptor completely. Offloading
     the IPC that happens with the windows of other processes to another thread prevents
     the interceptor from dying but the window updates need to be locked or window movement
     is very jittery.
     */
    private var positionUpdateLock:pthread_mutex_t
    private let positionUpdateQueue:DispatchQueue
    
    init() {
        
        self.positionUpdateLock = pthread_mutex_t()
        pthread_mutex_init(&positionUpdateLock, nil)
        self.positionUpdateQueue = DispatchQueue(label: "positionUpdateQueue", qos: .userInteractive, attributes: .concurrent)
        self.pidObserver = PidObserver()
        self.keyInterceptor = KeyEventInterceptor(keyEventAction: self.keyEventAction)
        self.mouseInterceptor = MouseEventInterceptor(mouseEventAction: self.mouseEventAction)
    
    }
    
    /*
     Activates window manager
     returns: true if successful, false if unsuccessful
     */
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
        guard let code = Keycodes(rawValue: Int(event.getIntegerValueField(.keyboardEventKeycode))) else {
            return nil
        }
        
        if let _ = transformer {} else {
            guard let activePid = self.activePid else { return unmodifiedEvent }
            transformer = WindowTransformer(forWindowWithPid: activePid)
        }
        
        // Command + W has been pressed
        if code == .w && event.flags.contains(.maskCommand) {
                        
            self.listeningEscapeAndMouseFlag = true
            return nil
        
            // Escape has been pressed while in window management mode
        } else if code == .esc && self.listeningEscapeAndMouseFlag {
            
            self.listeningEscapeAndMouseFlag = false
            self.transformer = nil
            return nil
            
        } else if DIRECTION_KEYCODES.contains(code) && self.listeningEscapeAndMouseFlag {
            
            self.windowDirectionShift(code: code)
            return nil
            
        // Something program does not care about happens
        } else {
            return unmodifiedEvent
        }
    }
    
    // Given a display and a direction, return a rectangle representing half of the display in that direction
    private func windowForHalfOfDisplay(_ display: DisplayData, forSide: Direction) -> CGRect {
        switch forSide {
        case .top:
            return CGRect(origin: CGPoint(x: display.origin.x, y: display.origin.y),
                          size: CGSize(width: display.size.width, height: display.size.height / 2.0))
        case .bottom:
            return CGRect(origin: CGPoint(x: display.origin.x, y: display.origin.y + (display.size.height / 2.0)),
                          size: CGSize(width: display.size.width, height: display.size.height / 2.0))
        case .left:
            return CGRect(origin: CGPoint(x: display.origin.x, y: display.origin.y),
                          size: CGSize(width: display.size.width / 2.0, height: display.size.height))
        case .right:
            return CGRect(origin: CGPoint(x: display.origin.x + (display.size.width / 2.0), y: display.origin.y),
                   size: CGSize(width: display.size.width / 2.0, height: display.size.height))
        }
    }
    
    /*
     Based on keycodes corresponding to a direction, attempt to make the selected window
     occupy half of the screen either on the top, bottom, left, or right.  Will attempt
     first to occupy the corresponding direction on the display the window is mostly on
     unless the window is already in that location, in which case the function will try
     to make the window occupy the opposite side of the adjacent display in that direction,
     should one exist.
     */
    private func windowDirectionShift(code: Keycodes) {
        
        guard let currentWindowPosition = transformer?.getCurrentWindowPosition() else { return }
        guard let currentWindowSize = transformer?.getCurrentWindowSize() else { return }
        let windowRect = CGRect(origin: currentWindowPosition, size: currentWindowSize)
        
        // Figure out which display most of the focused window is in
        let display = DisplayManager.getDisplayListData().max { l, r in
            l.frame.intersection(windowRect).area < r.frame.intersection(windowRect).area
        }
                
        guard let display = display else { return }
        
        let moveTo:Direction

        // Figure out which direction to try to shift the window based on keys corresponding to that direction
        switch code {
        case .left, .h:
            moveTo = .left
        case .right, .l:
            moveTo = .right
        case .down, .j:
            moveTo = .bottom
        case .up, .k:
            moveTo = .top
        default:
            return
        }
        
        var proposedWindowRect = windowForHalfOfDisplay(display, forSide: moveTo)
        if proposedWindowRect == lastWindowRect && self.activePid == transformer?.pid {
            print("Did change proposed window")
            let adjacentDisplay = DisplayManager.getAdjacentDisplay(to: moveTo, sourceDisplay: display)
            guard let adjacentDisplay = adjacentDisplay else {
                return
            }
            proposedWindowRect = windowForHalfOfDisplay(adjacentDisplay, forSide: moveTo.opposite())
        } else {
            print("Didn't change proposed window")
        }
        
        do {
            try transformer?.setPositionAndSize(proposedWindowRect)
            lastWindowRect = proposedWindowRect
        } catch {
            lastWindowRect = nil
            log("Error shifting window!")
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
                
        if let _ = transformer {} else {
            guard let activePid = self.activePid else { return unmodifiedEvent }
            transformer = WindowTransformer(forWindowWithPid: activePid)
        }

        let eventLocation = event.location

        let deltaEvent = NSEvent.init(cgEvent: event)
        let deltaX = deltaEvent?.deltaX
        let deltaY = deltaEvent?.deltaY

        guard let deltaX = deltaX, let deltaY = deltaY else { return nil }

        // Attempt to move window based on mouse events
        positionUpdateQueue.async {
            guard 0 == pthread_mutex_trylock(&self.positionUpdateLock) else { return }
            self.transformer?.transformWindowWithDeltas(x: deltaX, y: deltaY, forEvent: event)
            pthread_mutex_unlock(&self.positionUpdateLock)
        }

        CGWarpMouseCursorPosition(eventLocation) // Don't move cursor

        return nil
    }
    
}

