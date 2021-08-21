//
//  main.swift
//  Kinesis
//
//  Created by Lannie Hough on 8/21/21.
//

import Foundation
import CoreGraphics
import AppKit

main()

func observeActivePid(_ usePid: @escaping (pid_t?) -> Void) {
    
    let notificationCenter = NSWorkspace.shared.notificationCenter
    let activeNotification = NSWorkspace.didActivateApplicationNotification
    let queue = OperationQueue.main
    
    let notificationAction:(Notification) -> Void = { notification in
        //let workspace = notification.object as? NSWorkspace

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
    
    observeActivePid({ pid in
        print(pid)
    })
    
    RunLoop.main.run()

    
//    let displayId = CGMainDisplayID()
//    print(displayId)
//    while true {
//        sleep(100)
//    }
    //let windowId = CGWindowID()
    //let x = CGWindowListCopyWindowInfo(.optionOnScreenOnly, windowId)
    //print(x)
    
}
