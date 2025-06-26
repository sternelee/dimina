//
//  DMPEngineTimer.swift
//  dimina
//
//  Created by Lehem on 2025/5/12.
//

import Foundation
import JavaScriptCore

@available(iOS 13.0, *)
public class DMPEngineTimer {
    
    private var timers = [Int: DispatchSourceTimer]()
    private var timerCounter = 0
    private let queue = DispatchQueue(label: "com.dimina.timer", qos: .userInitiated)
    
    public static let shared = DMPEngineTimer()
    
    private init() {}
    
    public static func registerTimerFunctions(to context: JSContext) {
        let setTimeout: @convention(block) (JSValue, Double) -> Int = {
            [weak context] callback, delay in
            guard let jsContext = context, !callback.isUndefined else {
                return 0
            }
            
            return shared.createTimeout(callback: callback, context: jsContext, delay: delay)
        }
        
        let clearTimeout: @convention(block) (Int) -> Void = { timerId in
            shared.clearTimer(timerId: timerId)
        }
        
        let setInterval: @convention(block) (JSValue, Double) -> Int = {
            [weak context] callback, interval in
            guard let jsContext = context, !callback.isUndefined else {
                return 0
            }
            
            return shared.createInterval(callback: callback, context: jsContext, interval: interval)
        }
        
        let clearInterval: @convention(block) (Int) -> Void = { timerId in
            shared.clearTimer(timerId: timerId)
        }
        
        context.setObject(setTimeout, forKeyedSubscript: "setTimeout" as NSString)
        context.setObject(clearTimeout, forKeyedSubscript: "clearTimeout" as NSString)
        context.setObject(setInterval, forKeyedSubscript: "setInterval" as NSString)
        context.setObject(clearInterval, forKeyedSubscript: "clearInterval" as NSString)
    }
    
    private func getNextTimerId() -> Int {
        return queue.sync {
            timerCounter += 1
            return timerCounter
        }
    }
    
    private func createTimeout(callback: JSValue, context: JSContext, delay: Double) -> Int {
        return queue.sync {
            let timerId = timerCounter + 1
            timerCounter = timerId
            
            let delayMs: Int
            if delay.isFinite, let safeInt = Int(exactly: delay.rounded()) {
                delayMs = max(safeInt, 0)
            } else {
                delayMs = 0
            }
            
            let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
            timer.schedule(deadline: .now() + .milliseconds(delayMs))
            
            timer.setEventHandler { [weak context] in
                guard let jsContext = context, !callback.isUndefined else { return }
                
                jsContext.virtualMachine.addManagedReference(callback, withOwner: self)
                
                callback.call(withArguments: [])
                
                jsContext.virtualMachine.removeManagedReference(callback, withOwner: self)
                
                self.removeTimer(timerId: timerId)
            }
            
            timers[timerId] = timer
            timer.resume()
            
            return timerId
        }
    }
    
    private func createInterval(callback: JSValue, context: JSContext, interval: Double) -> Int {
        return queue.sync {
            let timerId = timerCounter + 1
            timerCounter = timerId
            
            let intervalMs: Int
            if interval.isFinite, let safeInt = Int(exactly: interval.rounded()) {
                intervalMs = max(safeInt, 0)
            } else {
                intervalMs = 0
            }
            
            let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
            timer.schedule(
                deadline: .now() + .milliseconds(intervalMs),
                repeating: .milliseconds(intervalMs))
            
            timer.setEventHandler { [weak context] in
                guard let jsContext = context, !callback.isUndefined else { return }
                
                jsContext.virtualMachine.addManagedReference(callback, withOwner: self)
                
                callback.call(withArguments: [])
                
                jsContext.virtualMachine.removeManagedReference(callback, withOwner: self)
            }
            
            timers[timerId] = timer
            timer.resume()
            
            return timerId
        }
    }
    
    private func clearTimer(timerId: Int) {
        queue.sync {
            if let timer = timers[timerId] {
                timer.cancel()
                timers.removeValue(forKey: timerId)
            }
        }
    }
    
    private func removeTimer(timerId: Int) {
        queue.sync {
            if let timer = timers[timerId] {
                timer.cancel()
                timers.removeValue(forKey: timerId)
            }
        }
    }
    
    public func clearAllTimers() {
        queue.sync {
            for (_, timer) in timers {
                timer.cancel()
            }
            timers.removeAll()
        }
    }
}
