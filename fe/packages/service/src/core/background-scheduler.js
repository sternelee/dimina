/** Cooperative suspension shared by Worker, QuickJS and JavaScriptCore services. */
export class BackgroundScheduler {
	constructor(clock) {
		this.clock = clock
		this.paused = false
		this.timers = new Map()
		this.nextId = 0
		this.pending = []
		this.drainHandle = undefined
	}

	set(callback, delay = 0, repeat = false, args = []) {
		if (typeof callback !== 'function') throw new TypeError('Timer callback must be a function')
		const ms = Math.min(2147483647, Math.max(0, Number(delay) || 0))
		const id = ++this.nextId
		const timer = { callback, args, delay: ms, remaining: ms, repeat, handle: undefined, due: 0 }
		this.timers.set(id, timer)
		if (!this.paused) this.arm(id, timer)
		return id
	}

	arm(id, timer) {
		timer.due = this.clock.now() + timer.remaining
		timer.handle = this.clock.setTimeout(() => {
			if (this.paused || !this.timers.has(id)) return
			if (!timer.repeat) this.timers.delete(id)
			try { timer.callback(...timer.args) }
			finally {
				if (timer.repeat && this.timers.has(id)) {
					timer.remaining = Math.max(1, timer.delay)
					if (!this.paused) this.arm(id, timer)
				}
			}
		}, timer.remaining)
	}

	dispatch(action) {
		if (this.paused || this.pending.length || this.drainHandle !== undefined) {
			this.pending.push(action)
			this.scheduleDrain()
		}
		else action()
	}

	scheduleDrain() {
		if (this.paused || !this.pending.length || this.drainHandle !== undefined) return
		// One host wakeup per batch, rather than one native timer per queued message.
		this.drainHandle = this.clock.setTimeout(() => {
			this.drainHandle = undefined
			const batch = this.pending.splice(0, 64)
			for (let index = 0; index < batch.length; index++) {
				if (this.paused) {
					this.pending = batch.slice(index).concat(this.pending)
					break
				}
				batch[index]()
			}
			this.scheduleDrain()
		}, 0)
	}

	clear(id) {
		const timer = this.timers.get(id)
		if (!timer) return
		this.clock.clearTimeout(timer.handle)
		this.timers.delete(id)
	}

	pause() {
		if (this.paused) return
		this.paused = true
		this.clock.clearTimeout(this.drainHandle)
		this.drainHandle = undefined
		for (const timer of this.timers.values()) {
			timer.remaining = Math.max(0, timer.due - this.clock.now())
			this.clock.clearTimeout(timer.handle)
		}
	}

	resume() {
		if (!this.paused) return
		this.paused = false
		for (const [id, timer] of this.timers) this.arm(id, timer)
		this.scheduleDrain()
	}
}

let scheduler
export function installBackgroundScheduler(target = globalThis) {
	if (scheduler) return scheduler
	scheduler = new BackgroundScheduler({
		now: () => target.performance?.now?.() ?? Date.now(),
		setTimeout: target.setTimeout.bind(target),
		clearTimeout: target.clearTimeout.bind(target),
	})
	target.setTimeout = (fn, delay, ...args) => scheduler.set(fn, delay, false, args)
	target.setInterval = (fn, delay, ...args) => scheduler.set(fn, delay, true, args)
	target.clearTimeout = target.clearInterval = id => scheduler.clear(id)
	return scheduler
}
export function dispatchBackgroundWork(action) {
	if (scheduler) scheduler.dispatch(action)
	else action()
}
export function pauseBackgroundWork() { scheduler?.pause() }
export function resumeBackgroundWork() { scheduler?.resume() }
