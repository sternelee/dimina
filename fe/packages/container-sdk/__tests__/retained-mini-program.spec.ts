import { beforeEach, expect, it, vi } from 'vitest'
import { createContainer } from '../src/index.js'
import { FakeWorker, resetFakeWorker } from './fixtures/fake-worker.js'
import { installFetchMock } from './fixtures/mock-fetch.js'

beforeEach(() => {
	installFetchMock()
	resetFakeWorker()
})

it('restores A after opening and hiding B without replacing its runtime or page', async () => {
	const mount = document.createElement('div')
	document.body.appendChild(mount)
	const container = createContainer({ mount })
	const first = await container.openApp({ appId: 'retained-a' })
	const page = first.navigator.top
	const worker = FakeWorker.instances[0]
	const hide = async () => {
		container.closeApp()
		await vi.waitFor(() => expect(container.application.views).toHaveLength(0))
	}
	await hide()
	const second = await container.openApp({ appId: 'retained-b' })
	await hide()

	expect(await container.openApp({ appId: 'retained-a' })).toBe(first)
	expect(first.navigator.top).toBe(page)
	expect(worker.terminate).not.toHaveBeenCalled()
	expect(container.application.appManager.getAppById('retained-b')).toBe(second)
	expect(FakeWorker.instances).toHaveLength(2)
	await container.application.destroyRootView(first)
	await container.application.destroyRootView(second)
	mount.remove()
}, 10000)

it('refreshes host entry options without reviving an old mini-program opener', async () => {
	const mount = document.createElement('div')
	document.body.appendChild(mount)
	const container = createContainer({ mount })
	const manager = container.application.appManager
	const source = await container.openApp({ appId: 'source' })
	const target = await manager.navigateToMiniProgram({ appId: 'target', extraData: { old: true } }, source)
	const worker = FakeWorker.instances[1]
	const page = target.navigator.top
	await vi.waitFor(() => expect(worker.postMessage.mock.calls.some(([msg]) => msg.type === 'loadResource')).toBe(true))
	await container.application.dismissView(target, { destroy: false })
	await container.application.dismissView(source, { destroy: false })

	const lastShow = () => worker.postMessage.mock.calls.map(([msg]) => msg).filter(msg => msg.type === 'appShow').at(-1)?.body
	try {
		expect(await container.openApp({ appId: 'target', scene: 1011 })).toBe(target)
		expect(target.navigator.top).toBe(page)
		expect(target.opener).toBeNull()
		expect(lastShow()).toEqual({
			scene: 1011, path: target.getCurrentPagePath(), query: target.getCurrentPageQuery(), referrerInfo: {},
		})
		await expect(manager.navigateBackMiniProgram(target, {}, async () => {})).rejects.toThrow('not opened by another mini program')

		await container.application.dismissView(target, { destroy: false })
		await container.openApp({ appId: 'target' })
		expect(lastShow()?.scene).toBe(1001)
		expect(worker.terminate).not.toHaveBeenCalled()
	} finally {
		await container.application.destroyRootView(target)
		await container.application.destroyRootView(source)
		mount.remove()
	}
})
