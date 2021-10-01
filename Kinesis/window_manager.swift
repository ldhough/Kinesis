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
    
    private func windowDirectionShift(code: Keycodes) {
        
        guard let currentWindowPosition = transformer?.getCurrentWindowPosition() else { return }
        guard let currentWindowSize = transformer?.getCurrentWindowSize() else { return }
        let windowRect = CGRect(origin: currentWindowPosition, size: currentWindowSize)
        
        // Figure out which display most of the focused window is in
        let display = DisplayManager.getDisplayListData().max { l, r in
            l.frame.intersection(windowRect).area < r.frame.intersection(windowRect).area
        }
                
        guard let display = display else { return }
        
        do {
            switch code {
            case .left, .h:
                try transformer?.setPosition(to: CGPoint(x: display.origin.x, y: display.origin.y))
                try transformer?.setSize(to: CGSize(width: display.size.width / 2.0, height: display.size.height))
                break
            case .right, .l:
                try transformer?.setPosition(to: CGPoint(x: display.origin.x + (display.size.width / 2.0), y: display.origin.y))
                try transformer?.setSize(to: CGSize(width: display.size.width / 2.0, height: display.size.height))
            case .down, .j:
                try transformer?.setPosition(to: CGPoint(x: display.origin.x, y: display.origin.y + (display.size.height / 2.0)))
                try transformer?.setSize(to: CGSize(width: display.size.width, height: display.size.height / 2.0))
                break
            case .up, .k:
                try transformer?.setPosition(to: CGPoint(x: display.origin.x, y: display.origin.y))
                try transformer?.setSize(to: CGSize(width: display.size.width, height: display.size.height / 2.0))
                break
            default:
                return
            }
        } catch {
            
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

