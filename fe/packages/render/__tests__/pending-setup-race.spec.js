/**
 * 测试目标：验证 render 侧 _waitForPendingSetups 机制能正确解决
 * IntersectionObserver 回调早于子组件 created 生命周期到达 service 侧的竞态问题。
 *
 * 背景：
 *   - service 侧发出 addIntersectionObserver（invokeAPI）是同步分发
 *   - service 侧发出 setData（'u' 消息）在 render 侧经 queueMicrotask 延迟处理
 *   - 子组件 setup 中 await message.wait(moduleId) 需等待 service created 完成才解除
 *   - 若 IntersectionObserver 在 pending setup 期间建立，首次回调会早于 created 抵达 service
 *   - 修复：render 侧用 _pendingSetupCount 追踪"仍在等待 service created 完成"的组件数，
 *           addIntersectionObserver 必须等计数归零后才建立 observer
 */

import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

// ─── 被测逻辑的最小实现（镜像自 runtime.js，与生产代码保持一致）─────────────────

class PendingSetupTracker {
	constructor() {
		this._pendingSetupCount = 0
		this._pendingSetupResolvers = []
	}

	/** 对应 setup 中 message.send('mC') 之后：计数 +1 */
	beginSetup() {
		this._pendingSetupCount++
	}

	/** 对应 setup 中 await message.wait(moduleId) 解除之后：计数 -1，通知等待者 */
	completeSetup() {
		this._pendingSetupCount--
		if (this._pendingSetupCount === 0 && this._pendingSetupResolvers.length > 0) {
			const resolvers = this._pendingSetupResolvers.splice(0)
			resolvers.forEach(resolve => resolve())
		}
	}

	/** 对应 addIntersectionObserver 中的等待逻辑 */
	waitForPendingSetups() {
		if (this._pendingSetupCount === 0) {
			return Promise.resolve()
		}
		return new Promise((resolve) => {
			this._pendingSetupResolvers.push(resolve)
		})
	}
}

// ─── 辅助：模拟 service 侧事件总线（对应 EventBus.once / emit）────────────────

function createEventBus() {
	const listeners = {}
	return {
		once(event, fn) {
			listeners[event] = fn
		},
		emit(event, payload) {
			if (listeners[event]) {
				listeners[event](payload)
				delete listeners[event]
			}
		},
		has(event) {
			return !!listeners[event]
		},
	}
}

// ─── 辅助：模拟组件初始化流程 ──────────────────────────────────────────────────

/**
 * 模拟一个子组件的完整初始化：
 *   render 侧 setup 发出 mC → 等待 service created（异步）→ created 中注册事件 → completeSetup
 *
 * @param {PendingSetupTracker} tracker
 * @param {object} eventBus  service 侧事件总线
 * @param {number} createdDelay  模拟 service 侧 created 耗时（ms）
 */
async function simulateComponentSetup(tracker, eventBus, createdDelay = 0) {
	// render 侧：发出 mC，计数 +1
	tracker.beginSetup()

	// service 侧：异步执行 #invokeInitLifecycle → await created()
	const serviceCreatedPromise = new Promise((resolve) => {
		setTimeout(() => {
			// created 中注册事件监听（对应 EventBus.once('needFeedBack', ...)）
			eventBus.once('needFeedBack', () => {})
			resolve()
		}, createdDelay)
	})

	// 等待 service created 完成后，render 侧 message.wait 解除
	await serviceCreatedPromise
	tracker.completeSetup()
}

// ─── 测试套件 ──────────────────────────────────────────────────────────────────

describe('_waitForPendingSetups：pending setup 计数器行为', () => {
	let tracker

	beforeEach(() => {
		tracker = new PendingSetupTracker()
	})

	it('初始状态下 pendingSetupCount 为 0', () => {
		expect(tracker._pendingSetupCount).toBe(0)
	})

	it('无 pending setup 时 waitForPendingSetups 立即 resolve', async () => {
		const resolved = vi.fn()
		await tracker.waitForPendingSetups().then(resolved)
		expect(resolved).toHaveBeenCalledOnce()
	})

	it('beginSetup 后 pendingSetupCount 递增', () => {
		tracker.beginSetup()
		expect(tracker._pendingSetupCount).toBe(1)

		tracker.beginSetup()
		expect(tracker._pendingSetupCount).toBe(2)
	})

	it('completeSetup 后 pendingSetupCount 递减', () => {
		tracker.beginSetup()
		tracker.beginSetup()
		tracker.completeSetup()
		expect(tracker._pendingSetupCount).toBe(1)
	})

	it('所有 pending setup 完成后等待者被 resolve', async () => {
		tracker.beginSetup()
		tracker.beginSetup()

		const resolved = vi.fn()
		const waitPromise = tracker.waitForPendingSetups().then(resolved)

		// 完成第一个：等待者还不应被通知
		tracker.completeSetup()
		await Promise.resolve() // flush microtasks
		expect(resolved).not.toHaveBeenCalled()

		// 完成第二个：等待者应被通知
		tracker.completeSetup()
		await waitPromise
		expect(resolved).toHaveBeenCalledOnce()
	})

	it('多个等待者同时被 resolve', async () => {
		tracker.beginSetup()

		const resolved1 = vi.fn()
		const resolved2 = vi.fn()
		const p1 = tracker.waitForPendingSetups().then(resolved1)
		const p2 = tracker.waitForPendingSetups().then(resolved2)

		tracker.completeSetup()
		await Promise.all([p1, p2])

		expect(resolved1).toHaveBeenCalledOnce()
		expect(resolved2).toHaveBeenCalledOnce()
	})

	it('resolvers 数组在通知后被清空，不会重复触发', async () => {
		tracker.beginSetup()

		const resolved = vi.fn()
		const waitPromise = tracker.waitForPendingSetups().then(resolved)

		tracker.completeSetup()
		await waitPromise

		// 再次开始并完成一个 setup，之前的 resolver 不应再触发
		tracker.beginSetup()
		tracker.completeSetup()
		await Promise.resolve()

		expect(resolved).toHaveBeenCalledTimes(1)
	})
})

describe('竞态场景：IntersectionObserver 与子组件 created 的时序', () => {
	let tracker
	let eventBus
	let observerCallbackLog // 记录 observer 触发时 EventBus 监听是否已注册

	beforeEach(() => {
		tracker = new PendingSetupTracker()
		eventBus = createEventBus()
		observerCallbackLog = []
	})

	/**
	 * 模拟 addIntersectionObserver 的行为：
	 *   等待 pending setups 完成 → 建立 observer → 立即触发首次回调（元素已在视口）
	 *   → emit needFeedBack
	 */
	async function simulateAddIntersectionObserver() {
		await tracker.waitForPendingSetups()

		// observer 建立后立即触发（元素已在视口）
		const listenerRegisteredBeforeEmit = eventBus.has('needFeedBack')
		observerCallbackLog.push({ listenerRegisteredBeforeEmit })
		eventBus.emit('needFeedBack')
	}

	it('【复现竞态】不等待 pending setup：observer 回调触发时 EventBus 监听尚未注册', async () => {
		// 模拟子组件初始化开始（但 created 尚未完成）
		tracker.beginSetup()

		// 未等待：直接模拟 IntersectionObserver 触发（旧 setTimeout/nextTick 方案可能的情况）
		const listenerRegisteredBeforeEmit = eventBus.has('needFeedBack')
		observerCallbackLog.push({ listenerRegisteredBeforeEmit })
		eventBus.emit('needFeedBack')

		// service 侧 created 完成后注册监听（此时 emit 已发出，事件已错过）
		await new Promise(resolve => setTimeout(resolve, 0))
		eventBus.once('needFeedBack', () => {})
		tracker.completeSetup()

		// EventBus 监听在 emit 时尚未注册 → 事件丢失
		expect(observerCallbackLog[0].listenerRegisteredBeforeEmit).toBe(false)
		// 此时仍无人注册（旧监听已错过，新注册但事件已 emit）
		expect(eventBus.has('needFeedBack')).toBe(true) // 新监听还在，但永远不会收到刚才的事件
	})

	it('【验证修复】等待 pending setup：observer 回调触发时 EventBus 监听已注册', async () => {
		// 子组件初始化：beginSetup → async created（注册 EventBus）→ completeSetup
		const setupPromise = simulateComponentSetup(tracker, eventBus, 0)

		// addIntersectionObserver 等待 pending setups 完成后再触发
		const observerPromise = simulateAddIntersectionObserver()

		await Promise.all([setupPromise, observerPromise])

		// EventBus 监听在 observer 回调时已注册
		expect(observerCallbackLog[0].listenerRegisteredBeforeEmit).toBe(true)
	})

	it('【验证修复】子组件 created 有耗时（async）时也能保证顺序', async () => {
		// 模拟 created 内部有 await（如异步接口调用）
		const setupPromise = simulateComponentSetup(tracker, eventBus, 10)
		const observerPromise = simulateAddIntersectionObserver()

		await Promise.all([setupPromise, observerPromise])

		expect(observerCallbackLog[0].listenerRegisteredBeforeEmit).toBe(true)
	})

	it('多个子组件同时初始化：全部 created 完成后 observer 才触发', async () => {
		const setup1 = simulateComponentSetup(tracker, eventBus, 5)
		const setup2 = simulateComponentSetup(tracker, eventBus, 15)

		const observerPromise = simulateAddIntersectionObserver()

		await Promise.all([setup1, setup2, observerPromise])

		// observer 触发时，两个子组件的 created 都已完成
		expect(observerCallbackLog[0].listenerRegisteredBeforeEmit).toBe(true)
		// pendingSetupCount 最终归零
		expect(tracker._pendingSetupCount).toBe(0)
	})

	it('observer 在所有 setup 完成后调用：无需等待，立即执行', async () => {
		// 先让子组件初始化完成
		await simulateComponentSetup(tracker, eventBus, 0)

		// 此时 pendingSetupCount 已为 0
		expect(tracker._pendingSetupCount).toBe(0)

		// addIntersectionObserver 此时调用，应立即（同一微任务周期内）resolve
		const start = Date.now()
		await simulateAddIntersectionObserver()
		const elapsed = Date.now() - start

		// 无额外延迟（相比 setTimeout(300) 或 setTimeout(500)）
		expect(elapsed).toBeLessThan(50)
		expect(observerCallbackLog[0].listenerRegisteredBeforeEmit).toBe(true)
	})
})

describe('边界情况', () => {
	let tracker

	beforeEach(() => {
		tracker = new PendingSetupTracker()
	})

	it('beginSetup/completeSetup 配对调用后计数保持为 0', () => {
		tracker.beginSetup()
		tracker.completeSetup()
		expect(tracker._pendingSetupCount).toBe(0)

		tracker.beginSetup()
		tracker.beginSetup()
		tracker.completeSetup()
		tracker.completeSetup()
		expect(tracker._pendingSetupCount).toBe(0)
	})

	it('setup 完成后新增等待者：新等待者立即 resolve', async () => {
		tracker.beginSetup()
		tracker.completeSetup()

		// 此时计数为 0，新的 waitForPendingSetups 应立即 resolve
		const resolved = vi.fn()
		await tracker.waitForPendingSetups().then(resolved)
		expect(resolved).toHaveBeenCalledOnce()
	})

	it('连续多次 waitForPendingSetups 在同一 pending 期间：全部等待同一次归零', async () => {
		tracker.beginSetup()

		const results = []
		const p1 = tracker.waitForPendingSetups().then(() => results.push(1))
		const p2 = tracker.waitForPendingSetups().then(() => results.push(2))
		const p3 = tracker.waitForPendingSetups().then(() => results.push(3))

		tracker.completeSetup()
		await Promise.all([p1, p2, p3])

		expect(results).toHaveLength(3)
		expect(tracker._pendingSetupResolvers).toHaveLength(0) // resolvers 已清空
	})
})
