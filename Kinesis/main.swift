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
        
    RunLoop.main.run()
}
