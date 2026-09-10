import { beforeEach, afterEach, expect, it, vi } from 'vitest'
const { handlers, send, page } = vi.hoisted(() => ({ handlers: {}, send: vi.fn(), page: { id: '' } }))
vi.mock('../src/core/message', () => ({ default: { on: (type, fn) => { handlers[type] = fn }, send } }))
vi.mock('../src/core/router', () => ({ default: { getPageInfo: () => page } }))
vi.mock('../src/api/common', () => ({ invokeAPI: vi.fn() }))
let debug, originalConsole
beforeEach(async () => {
	vi.resetModules(); send.mockReset()
	for (const key of Object.keys(handlers)) delete handlers[key]
	page.id = ''; originalConsole = { ...console }; globalThis.__diminaDebug = true
	debug = await import('../src/core/debug')
})
afterEach(() => { Object.assign(console, originalConsole); delete globalThis.__diminaDebug; delete globalThis.wx })
it('does not collect without the native debug flag', () => {
	globalThis.__diminaDebug = false; debug.installDebug()
	const options = { url: '/test' }
	expect(debug.debugRequest(options)).toBe(options)
	expect(handlers).toEqual({}); expect(console.log).toBe(originalConsole.log)
})
it('buffers startup logs until ready and preserves structured arguments', () => {
	debug.installDebug()
	const circular = { answer: 42 }; circular.self = circular
	console.log('startup', circular, 1n)
	expect(send).not.toHaveBeenCalled()
	page.id = 'a'; handlers.resourceLoaded({ bridgeId: 'a' })
	expect(send).toHaveBeenCalledOnce()
	expect(send.mock.lastCall[0].body).toEqual({ bridgeId: 'a', type: 'log', detail: { group: 'console', type: 'log', value: ['startup', { answer: 42, self: '[Circular]' }, '1'] } })
})
it('records completion on the originating page and preserves callbacks', () => {
	debug.installDebug(); page.id = 'a'; handlers.resourceLoaded({ bridgeId: 'a' })
	const success = vi.fn(), complete = vi.fn()
	const options = { url: 'https://example.com', method: 'POST', data: { a: 1 }, success, complete }
	const wrapped = debug.debugRequest(options); page.id = 'b'
	const result = { statusCode: 201, data: { ok: true }, header: { test: 'yes' } }
	wrapped.success(result)
	expect(success).toHaveBeenCalledExactlyOnceWith(result)
	expect(wrapped.complete).toBe(complete); expect(options.success).toBe(success)
	const records = send.mock.calls.map(([msg]) => msg.body)
	expect(records).toHaveLength(2); expect(records[1].bridgeId).toBe('a')
	expect(records[1].detail.value).toMatchObject({ id: records[0].detail.value.id, readyState: 4, status: 201, header: result.header, response: result.data, postData: { a: 1 } })
})
it('records failed requests', () => {
	debug.installDebug(); page.id = 'a'; handlers.resourceLoaded({ bridgeId: 'a' })
	const fail = vi.fn()
	debug.debugRequest({ url: '/fail', fail }).fail({ errMsg: 'request:fail offline' })
	expect(fail).toHaveBeenCalledOnce()
	expect(send.mock.lastCall[0].body.detail.value).toMatchObject({ readyState: 4, status: 0, response: 'request:fail offline' })
})
it('reads persisted storage through the mini-program API', async () => {
	debug.installDebug(); page.id = 'a'; handlers.resourceLoaded({ bridgeId: 'a' })
	globalThis.wx = { getStorageInfo: vi.fn().mockResolvedValue({ keys: ['existing'] }), getStorage: vi.fn().mockResolvedValue({ data: { n: 1 } }) }
	await handlers.debugStorage({ bridgeId: 'a' })
	expect(send).toHaveBeenCalledOnce()
	expect(globalThis.wx.getStorage).toHaveBeenCalledWith({ key: 'existing' })
	expect(send.mock.lastCall[0].body).toMatchObject({ bridgeId: 'a', detail: { group: 'storage', value: [{ key: 'existing', data: { n: 1 } }] } })
})
it('bounds early logs and discards queued data when a page unloads', () => {
	debug.installDebug(); page.id = 'a'
	for (let i = 0; i < 250; i++) console.log(i)
	handlers.resourceLoaded({ bridgeId: 'a' }); expect(send).toHaveBeenCalledTimes(200)
	handlers.pageUnload({ bridgeId: 'a' }); console.log('late')
	handlers.pageUnload({ bridgeId: 'a' }); handlers.resourceLoaded({ bridgeId: 'b' })
	expect(send).toHaveBeenCalledTimes(200)
})

it('instruments the public request API before callbacks enter the bridge', async () => {
	debug.installDebug(); page.id = 'a'; handlers.resourceLoaded({ bridgeId: 'a' })
	const { request } = await import('../src/api/core/network/request')
	const { invokeAPI } = await import('../src/api/common')
	request({ url: '/public' })
	const [name, options] = invokeAPI.mock.lastCall
	expect(name).toBe('request')
	expect(options.success).toBeTypeOf('function')
	options.success({ statusCode: 200, data: 'ok' })
	expect(send.mock.lastCall[0].body.detail.value).toMatchObject({ url: '/public', readyState: 4, response: 'ok' })
})
