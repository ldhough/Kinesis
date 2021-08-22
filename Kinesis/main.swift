//
//  main.swift
//  Kinesis
//
//  Created by Lannie Hough on 8/21/21.
//

import Foundation

main()

fileprivate func main() {
    
    let pidObserver = PidObserver()
    
    var active_pid:pid_t?
    var transformer:WindowTransformer?
    
//    pidObserver.observeActivePid({ pid in
//
//        active_pid = pid
//        guard let active_pid = active_pid else { return }
//
//        transformer = WindowTransformer(forWindowWithPid: active_pid)
//        do {
//            try transformer?.setPositionAndSize(CGPoint(x: 0, y: 0),
//                                                CGSize(width: 500, height: 500))
//        } catch {
//            log("Error setting position or size of window with pid \(active_pid)")
//        }
//
//    })
    
    let interceptor = KeyEventInterceptor(forKey: Keycodes.w, onPress: {
        log("COMMAND + W PRESSED")
    })
    interceptor.createKeyTap()
    interceptor.activateKeyTap()
    
    //log("\(interceptor.tapIsEnabled())")
    
    RunLoop.main.run()
}
