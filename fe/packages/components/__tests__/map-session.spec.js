import { createMapSession } from '../src/component/map/map-session'

function deferred() {
	let resolve
	const promise = new Promise(r => { resolve = r })
	return { promise, resolve }
}
function fixture(extra = {}) {
	const adapter = { update: vi.fn(), invoke: vi.fn(() => ({ scale: 16 })), destroy: vi.fn() }
	const emit = vi.fn()
	const createMap = vi.fn(async () => adapter)
	const session = createMapSession({ element: {}, props: {}, emit, config: { authorize: async () => true, provider: 'test', ...extra, providers: { test: { create: extra.createMap || createMap } } } })
	return { session, adapter, createMap, emit }
}
afterEach(() => vi.useRealTimers())

describe('map provider lifecycle', () => {
	it('never loads a provider without host privacy authorization', async () => {
		const { session, createMap, emit } = fixture({ authorize: async () => false })
		await expect(session.ready).rejects.toThrow('authorization denied')
		expect(createMap).not.toHaveBeenCalled()
		expect(emit).toHaveBeenCalledWith('error', { errMsg: expect.stringContaining('authorization denied') })
	})
	it('fails missing configuration without a network request', async () => {
		const session = createMapSession({ element: {}, props: {}, emit: vi.fn(), config: null })
		await expect(session.ready).rejects.toThrow('not configured')
	})
	it('keeps calls and prop updates in order while loading', async () => {
		const consent = deferred()
		const { session, adapter } = fixture({ authorize: () => consent.promise })
		const update = session.update({ scale: 18 })
		const call = session.invoke('getScale', {})
		expect(adapter.invoke).not.toHaveBeenCalled()
		consent.resolve(true)
		await update
		await expect(call).resolves.toEqual({ scale: 16 })
		expect(adapter.update.mock.invocationCallOrder[0]).toBeLessThan(adapter.invoke.mock.invocationCallOrder[0])
		session.destroy()
	})
	it('disposes a late factory result after unmount without emitting events', async () => {
		const factory = deferred()
		const { session, emit } = fixture({ createMap: () => factory.promise })
		await Promise.resolve()
		session.destroy()
		await expect(session.ready).rejects.toThrow('destroyed')
		const adapter = { destroy: vi.fn() }
		factory.resolve(adapter)
		await Promise.resolve()
		await Promise.resolve()
		expect(adapter.destroy).toHaveBeenCalledTimes(1)
		expect(emit).not.toHaveBeenCalled()
	})
	it('settles a pending call on destruction and disposes once', async () => {
		const { session, adapter } = fixture()
		await session.ready
		adapter.invoke.mockReturnValue(new Promise(() => {}))
		const pending = session.invoke('getScale', {})
		await Promise.resolve()
		session.destroy()
		session.destroy()
		await expect(pending).rejects.toThrow('destroyed')
		expect(adapter.destroy).toHaveBeenCalledTimes(1)
	})
	it('bounds initialization and disposes a late adapter after timeout', async () => {
		vi.useFakeTimers()
		const factory = deferred()
		const { session } = fixture({ createMap: () => factory.promise, timeout: 20 })
		const rejection = expect(session.ready).rejects.toThrow('timed out')
		await vi.advanceTimersByTimeAsync(21)
		await rejection
		const destroy = vi.fn()
		factory.resolve({ destroy })
		await Promise.resolve()
		await Promise.resolve()
		expect(destroy).toHaveBeenCalledTimes(1)
	})
	it('recovers the queue after an unsupported command', async () => {
		const { session, adapter } = fixture()
		adapter.invoke.mockImplementationOnce(() => { throw new Error('unsupported') })
		await expect(session.invoke('addArc', {})).rejects.toThrow('unsupported')
		await expect(session.invoke('getScale', {})).resolves.toEqual({ scale: 16 })
		session.destroy()
	})
})
