import { afterEach, describe, expect, it, vi } from 'vitest'

describe('render message handshake', () => {
	afterEach(() => {
		vi.resetModules()
		delete globalThis.window
	})

	it('registers the response listener before sending a synchronous request', async () => {
		globalThis.window = {
			DiminaRenderBridge: {
				publish: vi.fn((rawMessage) => {
					const request = JSON.parse(rawMessage)
					window.DiminaRenderBridge.onMessage({
						type: request.body.moduleId,
						body: { data: { created: true } },
					})
				}),
			},
		}

		const message = (await import('../src/core/message')).default
		const response = await message.waitAndSend('component-1', {
			type: 'mC',
			target: 'service',
			body: { bridgeId: 'bridge-1', moduleId: 'component-1' },
		})

		expect(response).toEqual({ created: true })
		expect(window.DiminaRenderBridge.publish).toHaveBeenCalledTimes(1)
	})
})
