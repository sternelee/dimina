//
//  DMPEngineTimer.swift
//  dimina
//
//  Created by Lehem on 2025/5/12.
//

import Foundation
import JavaScriptCore

public class DMPEngineTimer {
    
    private static var timers = [Int: Timer]()
    private static var timerCounter = 0
    
    public static func registerTimerFunctions(to context: JSContext) {
        let setTimeout: @convention(block) (JSValue, Double) -> Int = { callback, delay in
            let timerId = getNextTimerId()
            
            let timer = Timer.scheduledTimer(withTimeInterval: delay / 1000.0, repeats: false) { _ in
                callback.call(withArguments: [])
                timers.removeValue(forKey: timerId)
            }
            
            timers[timerId] = timer
            return timerId
        }
        
        let clearTimeout: @convention(block) (Int) -> Void = { timerId in
            if let timer = timers[timerId] {
                timer.invalidate()
                timers.removeValue(forKey: timerId)
            }
        }
        
        let setInterval: @convention(block) (JSValue, Double) -> Int = { callback, interval in
            let timerId = getNextTimerId()
            
            let timer = Timer.scheduledTimer(withTimeInterval: interval / 1000.0, repeats: true) { _ in
                callback.call(withArguments: [])
            }
            
            timers[timerId] = timer
            return timerId
        }
        
        let clearInterval: @convention(block) (Int) -> Void = { timerId in
            if let timer = timers[timerId] {
                timer.invalidate()
                timers.removeValue(forKey: timerId)
            }
        }
        
        context.setObject(setTimeout, forKeyedSubscript: "setTimeout" as NSString)
        context.setObject(clearTimeout, forKeyedSubscript: "clearTimeout" as NSString)
        context.setObject(setInterval, forKeyedSubscript: "setInterval" as NSString)
        context.setObject(clearInterval, forKeyedSubscript: "clearInterval" as NSString)
    }
    
    private static func getNextTimerId() -> Int {
        timerCounter += 1
        return timerCounter
    }
    
    public static func clearAllTimers() {
        for (_, timer) in timers {
            timer.invalidate()
        }
        timers.removeAll()
    }
} 