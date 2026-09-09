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
