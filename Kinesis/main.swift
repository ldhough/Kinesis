//
//  main.swift
//  Kinesis
//
//  Created by Lannie Hough on 8/21/21.
//

import Foundation
import CoreGraphics
import AppKit
import Accessibility

main()

func observeActivePid(_ usePid: @escaping (pid_t?) -> Void) {
    
    let notificationCenter = NSWorkspace.shared.notificationCenter
    let activeNotification = NSWorkspace.didActivateApplicationNotification
    let queue = OperationQueue.main
    
    let notificationAction:(Notification) -> Void = { notification in

        let info = notification.userInfo
        let app = info?[AnyHashable("NSWorkspaceApplicationKey")] as? NSRunningApplication
        
        guard let pid = app?.processIdentifier else {
            usePid(nil)
            return
        }
        
        usePid(pid)

    }
    
    notificationCenter.addObserver(forName: activeNotification, object: nil, queue: queue, using: notificationAction)
    
}

func main() {
    
    var active_pid:pid_t?
    
    observeActivePid({ pid in
        
        active_pid = pid
        guard let active_pid = active_pid else { return }
        
        print("Got pid: \(active_pid)")
        
        // Make Accessibility object for given PID
        let accessApp:AXUIElement = AXUIElementCreateApplication(active_pid)
        
        // Get value associated with kAXWindowsAttribute in windowData, create windowElement from this data
        var windowData:AnyObject?
        AXUIElementCopyAttributeValue(accessApp, kAXWindowsAttribute as CFString, &windowData)
        let windowElement:AXUIElement? = (windowData as? [AXUIElement])?.first
        
        var newPoint = CGPoint(x: 0, y: 0)
        var newSize = CGSize(width: 400, height: 400)
        let position:CFTypeRef = AXValueCreate(AXValueType(rawValue: kAXValueCGPointType)!, &newPoint)!
        let size:CFTypeRef = AXValueCreate(AXValueType(rawValue: kAXValueCGSizeType)!, &newSize)!
        
        AXUIElementSetAttributeValue(windowElement!, kAXPositionAttribute as CFString, position);
        AXUIElementSetAttributeValue(windowElement!, kAXSizeAttribute as CFString, size);

    })

    
    RunLoop.main.run()
    
}
