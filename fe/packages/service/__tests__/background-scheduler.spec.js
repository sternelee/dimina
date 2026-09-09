import { afterEach, beforeEach, expect, it, vi } from 'vitest'
import { BackgroundScheduler } from '../src/core/background-scheduler'

let scheduler
beforeEach(() => {
	vi.useFakeTimers()
	scheduler = new BackgroundScheduler({ now: () => Date.now(), setTimeout, clearTimeout })
})
afterEach(() => vi.useRealTimers())

it('freezes remaining timer time, preserves arguments and does not catch up intervals', () => {
	const events = []
	scheduler.set(value => events.push(value), 100, false, ['timeout'])
	scheduler.set(() => events.push('interval'), 100, true)
	vi.advanceTimersByTime(40)
	scheduler.pause()
	vi.advanceTimersByTime(5000)
	expect(events).toEqual([])
	expect(vi.getTimerCount()).toBe(0)
	scheduler.resume()
	vi.advanceTimersByTime(59)
	expect(events).toEqual([])
	vi.advanceTimersByTime(1)
	expect(events).toEqual(['timeout', 'interval'])
	vi.advanceTimersByTime(100)
	expect(events).toEqual(['timeout', 'interval', 'interval'])
})

it('supports cancelling and creating timers while suspended and repeated visibility signals', () => {
	const callback = vi.fn()
	scheduler.pause()
	const cancelled = scheduler.set(callback, 1)
	scheduler.clear(cancelled)
	scheduler.set(callback, 80)
	scheduler.pause()
	vi.advanceTimersByTime(1000)
	scheduler.resume()
	scheduler.resume()
	vi.advanceTimersByTime(79)
	expect(callback).not.toHaveBeenCalled()
	vi.advanceTimersByTime(1)
	expect(callback).toHaveBeenCalledTimes(1)
})

it('defers business callbacks in FIFO order until resume without replaying cancelled timers', () => {
	const events = []
	scheduler.pause()
	scheduler.dispatch(() => events.push('network'))
	scheduler.dispatch(() => events.push('animation'))
	vi.runOnlyPendingTimers()
	expect(events).toEqual([])
	scheduler.resume()
	vi.runOnlyPendingTimers()
	expect(events).toEqual(['network', 'animation'])
})

it('an interval cancelled from its callback is not rearmed', () => {
	const callback = vi.fn(() => scheduler.clear(id))
	const id = scheduler.set(callback, 1, true)
	vi.advanceTimersByTime(100)
	expect(callback).toHaveBeenCalledTimes(1)
	expect(vi.getTimerCount()).toBe(0)
})
