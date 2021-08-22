//
//  main.swift
//  Kinesis
//
//  Created by Lannie Hough on 8/21/21.
//

import Foundation
import AppKit

main()

fileprivate func main() {
    
    let pidObserver = PidObserver()
    
    var active_pid:pid_t?
    var transformer:WindowTransformer?
    
    var listeningEscapeAndMouseFlag = false
    
    pidObserver.observeActivePid({ pid in

        active_pid = pid
        //let t = WindowTransformer(forWindowWithPid: active_pid!)
        //t?.getCurrentWindowPosition()
//        do {
//            try transformer?.setPositionAndSize(CGPoint(x: 0, y: 0),
//                                                CGSize(width: 500, height: 500))
//        } catch {
//            log("Error setting position or size of window with pid \(active_pid)")
//        }

    })
    
    let keyInterceptor = KeyEventInterceptor(keyEventAction: { event in
        
        let unmodifiedEvent = Unmanaged.passRetained(event)
        let code = event.getIntegerValueField(.keyboardEventKeycode)
        
        // Command + W has been pressed
        if code == Keycodes.w.rawValue && event.flags.contains(.maskCommand) {
            
            log("COMMAND + W PRESSED")
            listeningEscapeAndMouseFlag = true
            return nil
        
        // Escape has been pressed while in window management mode
        } else if code == Keycodes.esc.rawValue && listeningEscapeAndMouseFlag {
            
            log("ESC PRESSED")
            listeningEscapeAndMouseFlag = false
            transformer = nil
            return nil
        // Something this program does not care about happens
        } else {
            return unmodifiedEvent
        }
    })
        
    let mouseInterceptor = MouseEventInterceptor(mouseEventAction: { event in
        
        let unmodifiedEvent = Unmanaged.passRetained(event)
        
        if !listeningEscapeAndMouseFlag {
            return unmodifiedEvent
        }
                
        guard let active_pid = active_pid else { return unmodifiedEvent }
        
        if let _ = transformer {} else {
            transformer = WindowTransformer(forWindowWithPid: active_pid)
        }
        
        let eventLocation = event.location

        let deltaEvent = NSEvent.init(cgEvent: event)
        let deltaX = deltaEvent?.deltaX
        let deltaY = deltaEvent?.deltaY
        
        guard let deltaX = deltaX, let deltaY = deltaY else { return nil }
        
        transformer!.transformWindowWithDeltas(x: deltaX, y: deltaY)
        
        print(eventLocation)
        
        CGWarpMouseCursorPosition(eventLocation) // Don't move cursor
        
        return nil
    })
    
    keyInterceptor.createKeyTap()
    keyInterceptor.activateTap()

    mouseInterceptor.createMouseTap()
    mouseInterceptor.activateTap()
        
    RunLoop.main.run()
}
