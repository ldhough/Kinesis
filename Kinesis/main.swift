//
//  main.swift
//  Kinesis
//
//  Created by Lannie Hough on 8/21/21.
//

import Foundation
import AppKit
import CoreGraphics

main()

fileprivate func main() {
    
    let windowManager = KinesisWindowManager()
    
    if !windowManager.start() {
        log("Error starting Kinesis window manager!")
        return
    }
    //let x = NSRect.fill(NSMakeRect(0.0, 0.0, 4.0, 4.0))
        
    RunLoop.main.run()
}
