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
    
    let windowManager = KinesisWindowManager()
    
    if !windowManager.start() {
        return
    }
        
    RunLoop.main.run()
}
