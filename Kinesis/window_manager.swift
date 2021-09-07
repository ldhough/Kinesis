//
//  window_manager.swift
//  Kinesis
//
//  Created by Lannie Hough on 8/22/21.
//

import Foundation
import AppKit

fileprivate typealias KWM = KinesisWindowManager

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
        if code.equals(.w) && event.flags.contains(.maskCommand) {
            
            log("CMD + W PRESSED")
            
            self.listeningEscapeAndMouseFlag = true
            return nil
        
        // Right arrow pressed while in window management mode
        } else if code.equals(.right) && self.listeningEscapeAndMouseFlag  {
            
            let panels = KWM.getDisplayListData()
            let hcpv = KWM.halfCenterPointsVertical(displays: panels)
            
            let displaySize = panels[0].frame.size
            let windowSize = CGSize(width: displaySize.width / 2.0, height: displaySize.height)
            do {
                try transformer?.setSize(to: windowSize)
                try transformer?.setPosition(to: CGPoint(x: displaySize.width / 2.0, y: 0))
            } catch {
                log("FAILED: transforming based on arrow key")
            }
            
//            let currentWindowCenterPoint = {
//                let currLocationTopLeft = transformer?.getCurrentWindowPosition()
//                let currentSize = transformer?.getCurrentWindowSize()
//            }()
//
//            let closest:CGPoint = {
//                var clt = CGPoint(x: CGFloat.greatestFiniteMagnitude, y: 0)
//                for point in hcpv {
//
//                }
//                return CGPoint(x: 0, y: 0)
//            }()
            
            return nil
        } else if code.equals(.left) && self.listeningEscapeAndMouseFlag {
            
            return nil
        } else if code.equals(.up) && self.listeningEscapeAndMouseFlag {
            
            return nil
        } else if code.equals(.down) && self.listeningEscapeAndMouseFlag {
            
            return nil
        // Escape has been pressed while in window management mode
        } else if code.equals(.esc) && self.listeningEscapeAndMouseFlag {
            
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

        //print("Mouse delta is x: \(deltaX) & y: \(deltaY)")

        // Attempt to move window based on mouse events
        transformer?.transformWindowWithDeltas(x: deltaX, y: deltaY, forEvent: event) 

        // Try alt?
        CGWarpMouseCursorPosition(eventLocation) // Don't move cursor

        return nil
    }
    
    private static func halfCenterPointsVertical(displays: [DisplayData]) -> [CGPoint] {
        var points:[CGPoint] = []
        for display in displays {
            let startPoint = CGPoint(x: display.frame.minX, y: display.frame.minY)
            
            let w = display.frame.width
            let h = display.frame.height
            let centerVertical = h / 2.0
            
            let quarterWidth = w / 4.0
            let centerHalfLeftHorizontal = startPoint.x + quarterWidth
            let centerHalfRightHorizontal = startPoint.x + (3.0 * quarterWidth)
            
            points.append(CGPoint(x: centerHalfLeftHorizontal, y: centerVertical))
            points.append(CGPoint(x: centerHalfRightHorizontal, y: centerVertical))
        }
        return points
    }
    
    private static func getDisplayList() -> [CGDirectDisplayID] {

        let max:UInt32 = 16
        var displays = [CGDirectDisplayID](repeating: 0, count: Int(max))
        var onlineDisplaysCount:UInt32 = 0
        let err = CGGetOnlineDisplayList(max,
                                         &displays,
                                         &onlineDisplaysCount)
        
        if err != .success {
            log("Error getting list of online displays: \(err)")
            return []
        }
        
        return displays
        
    }
    
    public static func getDisplayListData() -> [DisplayData] {
        KWM.getDisplayList().mapWithIndex({ idx, displayId in
            DisplayData(index: idx, frame: CGDisplayBounds(displayId))
        })
    }
    
}

