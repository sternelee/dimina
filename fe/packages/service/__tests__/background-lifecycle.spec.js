import { afterEach, expect, it, vi } from 'vitest'

afterEach(() => vi.useRealTimers())

it('hides before suspension, defers API callbacks, and keeps exit callbacks and barriers live', async () => {
	vi.resetModules()
	vi.useFakeTimers()
	globalThis.DiminaServiceBridge.invoke = vi.fn()
	const service = (await import('../src/index')).default
	const { callback } = await import('@dimina/common')
	const { invokeAPI } = await import('../src/api/common')
	const runtime = (await import('../src/core/runtime')).default
	const events = []
	runtime.app = { appHide: () => events.push('hide'), appShow: () => events.push('show') }
	const normalId = callback.store(() => events.push('network'))
	invokeAPI('exitMiniProgram', { success: () => events.push('exit'), complete: () => events.push('complete') })
	const params = globalThis.DiminaServiceBridge.invoke.mock.calls.at(-1)[0].body.params
	globalThis.setTimeout(() => events.push('timer'), 10)
	service.message.handleMsg({ type: 'appHide' })
	service.message.handleMsg({ type: 'triggerCallback', body: { id: normalId } })
	service.message.handleMsg({ type: 'triggerCallback', body: { id: params.success } })
	service.message.handleMsg({ type: 'triggerCallback', body: { id: params.complete } })
	service.message.handleMsg({ type: 'flushCallbacks', body: { requestId: 'exit-barrier' } })
	vi.advanceTimersByTime(1000)
	expect(events).toEqual(['hide', 'exit', 'complete'])
	expect(globalThis.DiminaServiceBridge.invoke).toHaveBeenLastCalledWith({
		type: 'callbacksFlushed', target: 'container', body: { requestId: 'exit-barrier' },
	})
	service.message.handleMsg({ type: 'appShow', body: {} })
	vi.advanceTimersByTime(10)
	expect(events).toEqual(['hide', 'exit', 'complete', 'show', 'network', 'timer'])
})
