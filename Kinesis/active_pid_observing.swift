//
//  active_pid_observing.swift
//  Kinesis
//
//  Created by Lannie Hough on 8/21/21.
//

import Foundation
import AppKit

class PidObserver {
    
    private let notificationCenter = NSWorkspace.shared.notificationCenter
    private let activeNotification = NSWorkspace.didActivateApplicationNotification
    //NSWorkspace.
    private let queue = OperationQueue.main

    // Listen for notifications indicating an application has been focused
    public func observeActivePid(_ usePid: @escaping (pid_t?) -> Void) {
        
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
    
    public func removeObserver() {
        
    }
    
    deinit {
        removeObserver()
    }

}
