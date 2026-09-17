import { beforeEach, describe, expect, it, vi } from 'vitest'
import { getEnterOptionsSync, getLaunchOptionsSync } from '../src/api/core/life-cycle'
import runtime from '../src/core/runtime'
import { App } from '../src/instance/app/app'

describe('mini program launch and enter options', () => {
	beforeEach(() => {
		runtime.app = undefined
		runtime.appLaunchOptions = {}
		runtime.appEnterOptions = {}
	})

	it('updates a retained app with the second host entry while preserving its launch and globalData (#342)', () => {
		const first = { scene: 1001, path: 'pages/index/index', query: { id: '1', from: 'first' }, referrerInfo: {} }
		runtime.setAppLaunchOptions(first)
		const onLaunch = vi.fn(), onShow = vi.fn(), onHide = vi.fn()
		const globalData = { records: ['first launch'] }
		const app = new App({ moduleInfo: { globalData, onLaunch, onShow, onHide } }, first)
		runtime.app = app
		runtime.appHide()
		runtime.appShow({ scene: 1001, pagePath: 'pages/index/index', query: { id: '2', from: 'second' }, referrerInfo: {} })

		const second = { ...first, query: { id: '2', from: 'second' } }
		expect(onLaunch).toHaveBeenCalledTimes(1)
		expect(onHide).toHaveBeenCalledTimes(1)
		expect(onShow).toHaveBeenCalledTimes(2)
		expect(onShow).toHaveBeenLastCalledWith(second)
		expect(getLaunchOptionsSync()).toEqual(first)
		expect(getEnterOptionsSync()).toEqual(second)
		expect(runtime.app).toBe(app)
		expect(app.globalData.records).toEqual(['first launch'])

		// Hosts supply the current page when returning from the background.
		runtime.appHide()
		runtime.appShow(first)
		expect(onShow).toHaveBeenLastCalledWith(first)
		expect(getEnterOptionsSync()).toEqual(first)
		expect(getLaunchOptionsSync()).toEqual(first)
	})

	it('returns shallow copies so replacing getter fields cannot rewrite launch or enter state', () => {
		const first = { path: 'pages/index/index', query: { id: '1' }, scene: 1001 }
		runtime.setAppLaunchOptions(first)
		runtime.appShow({ ...first, query: { id: '2' } })
		for (const getter of [getLaunchOptionsSync, getEnterOptionsSync]) {
			const snapshot = getter()
			const query = snapshot.query
			snapshot.path = 'changed'
			snapshot.query = {}
			expect(getter().path).toBe(first.path)
			expect(getter().query).toBe(query)
			expect(getter()).not.toBe(snapshot)
		}
	})

	it('keeps launch options stable while a mini-program return updates enter options and App.onShow', () => {
		const launchOptions = {
			scene: 1037,
			pagePath: 'pages/index/index',
			query: { from: 'source' },
			referrerInfo: { appId: 'source-app', extraData: { token: 'open' } },
		}
		runtime.setAppLaunchOptions(launchOptions)

		const appShow = vi.fn()
		runtime.app = { appShow }
		const returnOptions = {
			scene: 1038,
			path: 'pages/index/index',
			query: { from: 'source' },
			referrerInfo: { appId: 'target-app', extraData: { token: 'back' } },
		}
		runtime.appShow(returnOptions)

		expect(getLaunchOptionsSync()).toEqual({
			scene: 1037,
			path: 'pages/index/index',
			query: { from: 'source' },
			referrerInfo: { appId: 'source-app', extraData: { token: 'open' } },
		})
		expect(getEnterOptionsSync()).toEqual(returnOptions)
		expect(appShow).toHaveBeenCalledWith(returnOptions)
	})

	it('does not expose undefined referrerInfo and reuses the latest enter options on a plain foreground event', () => {
		runtime.setAppLaunchOptions({
			scene: 1001,
			pagePath: 'pages/index/index',
			query: {},
			referrerInfo: undefined,
		})
		const appShow = vi.fn()
		runtime.app = { appShow }

		runtime.appShow()

		expect(getLaunchOptionsSync()).toEqual({
			scene: 1001,
			path: 'pages/index/index',
			query: {},
		})
		expect(getEnterOptionsSync()).toEqual(getLaunchOptionsSync())
		expect(appShow).toHaveBeenCalledWith(getLaunchOptionsSync())
	})
})
