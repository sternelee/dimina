import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

// Keep request, invokeAPI, message transport and callback registration real.
// Only the host boundary is replaced; this does not send network traffic.
let request, callback, bridge, originalConsole

beforeEach(async () => {
	vi.resetModules()
	originalConsole = { ...console }
	bridge = { invoke: vi.fn(), publish: vi.fn() }
	vi.stubGlobal('DiminaServiceBridge', bridge)
	vi.stubGlobal('__diminaDebug', false)
	;({ request } = await import('../src/api/core/network/request/index.js'))
	;({ callback } = await import('@dimina/common'))
})

afterEach(() => {
	callback?.remove()
	Object.assign(console, originalConsole)
	vi.unstubAllGlobals()
})

function hostParams(index = 0) {
	const message = bridge.invoke.mock.calls[index][0]
	expect(message).toMatchObject({ type: 'invokeAPI', target: 'container', body: { name: 'request' } })
	// Verify the serializable payload native hosts consume, including callback IDs.
	return JSON.parse(JSON.stringify(message.body.params))
}

function networkRecords() {
	return bridge.publish.mock.calls.map(([, message]) => message.body)
		.filter(body => body.detail?.group === 'network')
		.map(body => body.detail.value)
}

describe.each([false, true])('request bridge with debug=%s', (debugEnabled) => {
	beforeEach(async () => {
		if (!debugEnabled) return
		vi.stubGlobal('__diminaDebug', true)
		const { default: router } = await import('../src/core/router.js')
		router.setInitId('request-page')
		const { installDebug } = await import('../src/core/debug.js')
		installDebug()
		bridge.onMessage({ type: 'resourceLoaded', body: { bridgeId: 'request-page' } })
	})

	it.each(['GET', 'HEAD', 'DELETE'])('%s reaches the host with encoded query, no body and working success callbacks', (method) => {
		const success = vi.fn(), fail = vi.fn(), complete = vi.fn()
		const data = Object.freeze({ transType: '20,30', list: ['甲', 'a+b'], nil: null, absent: undefined })
		const options = Object.freeze({
			url: 'https://example.com/bill?existing=a%2Cb', method, data,
			header: { Authorization: 'Bearer test', 'content-type': 'application/json' },
			success, fail, complete,
		})
		request(options)
		const params = hostParams()
		expect(params.url).toBe('https://example.com/bill?existing=a%2Cb&transType=20%2C30&list=%E7%94%B2&list=a%2Bb')
		expect(params.method).toBe(method)
		expect(params).not.toHaveProperty('data')
		expect(params.header).toEqual(options.header)
		expect(params.success).toEqual(expect.any(String))
		expect(params.fail).toEqual(expect.any(String))
		expect(params.complete).toEqual(expect.any(String))
		const result = { statusCode: 200, data: method === 'HEAD' ? '' : { ok: true }, header: {} }
		callback.invoke(params.success, result)
		callback.invoke(params.complete, result)
		expect(success).toHaveBeenCalledExactlyOnceWith(result)
		expect(complete).toHaveBeenCalledExactlyOnceWith(result)
		expect(fail).not.toHaveBeenCalled()
		expect(options.url).toBe('https://example.com/bill?existing=a%2Cb')
		expect(options.data).toBe(data)
		if (debugEnabled) {
			expect(networkRecords()).toEqual([
				expect.objectContaining({ url: params.url, method, readyState: 1 }),
				expect.objectContaining({ url: params.url, method, readyState: 4, status: 200, response: result.data }),
			])
		}
		else expect(networkRecords()).toEqual([])
	})

	it('keeps repeated calls independent when the same options are reused and results arrive out of order', () => {
		const success = vi.fn(), fail = vi.fn(), complete = vi.fn()
		const options = { url: 'https://example.com/bill', data: { page: 1 }, success, fail, complete }
		request(options)
		request(options)
		const first = hostParams(0), second = hostParams(1)
		expect(first.url).toBe('https://example.com/bill?page=1')
		expect(second.url).toBe(first.url)
		expect(second.success).not.toBe(first.success)
		const error = { errMsg: 'request:fail offline' }
		const result = { statusCode: 200, data: 'ok' }
		callback.invoke(second.fail, error)
		callback.invoke(second.complete, error)
		callback.invoke(first.success, result)
		callback.invoke(first.complete, result)
		expect(fail).toHaveBeenCalledExactlyOnceWith(error)
		expect(success).toHaveBeenCalledExactlyOnceWith(result)
		expect(complete.mock.calls).toEqual([[error], [result]])
		if (debugEnabled) {
			const records = networkRecords()
			expect(records).toHaveLength(4)
			expect(records[2]).toMatchObject({ id: records[1].id, url: second.url, status: 0, response: error.errMsg })
			expect(records[3]).toMatchObject({ id: records[0].id, url: first.url, status: 200, response: 'ok' })
		}
	})

	it('keeps POST JSON payload intact across bridge serialization', () => {
		request({ url: 'https://example.com/bill?existing=1', method: 'POST', data: { transType: '20,30', list: ['a', 'b'], nil: null } })
		expect(hostParams()).toMatchObject({
			url: 'https://example.com/bill?existing=1', method: 'POST',
			data: { transType: '20,30', list: ['a', 'b'], nil: null },
		})
	})
})
