import { describe, expect, it, vi } from 'vitest'
import { Bridge } from '../src/core/bridge'

describe('Bridge resource loading protocol', () => {
	it('forwards render failures without marking resources as loaded', () => {
		const jscore = { postMessage: vi.fn() }
		const bridge = new Bridge({
			jscore,
			pagePath: 'pages/index/index',
			scene: 1001,
			query: {},
		})
		bridge.id = 'bridge-failure'
		bridge.serviceResource = true
		bridge.renderResource = true

		bridge.messageInvoke('render', {
			type: 'renderResourceLoadFailed',
			target: 'service',
			body: {
				bridgeId: bridge.id,
				errors: ['script failed'],
			},
		})

		expect(bridge.renderResource).toBe(false)
		expect(bridge.isResourceLoaded()).toBe(false)
		expect(jscore.postMessage).toHaveBeenCalledWith({
			type: 'resourceLoadFailed',
			body: {
				bridgeId: bridge.id,
				pagePath: 'pages/index/index',
				scene: 1001,
				query: {},
				errors: ['script failed'],
			},
		})
	})
})
