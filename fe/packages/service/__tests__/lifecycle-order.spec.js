import { beforeEach, describe, expect, it, vi } from 'vitest'
import runtime from '../src/core/runtime'
import { Component } from '../src/instance/component/component'
import { ComponentModule } from '../src/instance/component/component-module'
import { Page } from '../src/instance/page/page'
import { PageModule } from '../src/instance/page/page-module'

describe('Skyline/exparser lifecycle ordering', () => {
	beforeEach(() => {
		runtime.instances = {}
		runtime.pageStates.clear()
		globalThis.DiminaServiceBridge.publish = vi.fn(() => Promise.resolve())
	})

	it('runs onLoad, onShow, component ready and page onReady once in render acknowledgement order', async () => {
		const calls = []
		const bridgeId = 'bridge-page-lifecycle'
		const pageModule = new PageModule({
			onLoad() {
				calls.push('page:onLoad')
			},
			onShow() {
				calls.push('page:onShow')
			},
			onReady() {
				calls.push('page:onReady')
			},
		}, {
			path: 'pages/lifecycle/index',
			usingComponents: {},
		})
		const page = new Page(pageModule, {
			bridgeId,
			moduleId: 'page-1',
			path: 'pages/lifecycle/index',
			query: {},
		})
		await page.init()

		const component = {
			__id__: 'component-1',
			__type__: ComponentModule.type,
			__isComponent__: true,
			__componentAttached__: true,
			__componentReadied__: true,
			initd: true,
			pageShow: () => calls.push('component:show'),
		}
		runtime.instances[bridgeId] = {
			[page.__id__]: page,
			[component.__id__]: component,
		}

		runtime.pageReady({ bridgeId, moduleId: page.__id__ })
		runtime.pageShow({ bridgeId })
		runtime.pageReady({ bridgeId, moduleId: page.__id__ })

		expect(calls).toEqual([
			'page:onLoad',
			'component:show',
			'page:onShow',
			'page:onReady',
		])
	})

	it('queues an early pageShow until the page instance has finished onLoad', async () => {
		const calls = []
		const bridgeId = 'bridge-early-show'

		runtime.pageShow({ bridgeId })
		const page = {
			__id__: 'page-1',
			__type__: PageModule.type,
			initd: false,
			pageShow: () => calls.push('page:onShow'),
		}
		runtime.instances[bridgeId] = { [page.__id__]: page }
		runtime.pageShow({ bridgeId })
		expect(calls).toEqual([])

		page.initd = true
		runtime.pageShow({ bridgeId })
		expect(calls).toEqual(['page:onShow'])
	})

	it('does not reshow a hidden page when render acknowledges pageReady', () => {
		const calls = []
		const bridgeId = 'bridge-hidden-ready'
		const page = {
			__id__: 'page-1',
			__type__: PageModule.type,
			initd: true,
			pageShow: () => calls.push('page:onShow'),
			pageHide: () => calls.push('page:onHide'),
			pageReady: () => calls.push('page:onReady'),
		}
		runtime.instances[bridgeId] = { [page.__id__]: page }

		runtime.pageShow({ bridgeId })
		runtime.pageHide({ bridgeId })
		runtime.pageReady({ bridgeId, moduleId: page.__id__ })

		expect(calls).toEqual(['page:onShow', 'page:onHide'])
		expect(runtime.getPageState(bridgeId)).toMatchObject({
			hidden: true,
			pendingReady: true,
			ready: false,
			shown: false,
		})

		runtime.pageShow({ bridgeId })
		expect(calls).toEqual([
			'page:onShow',
			'page:onHide',
			'page:onShow',
			'page:onReady',
		])
	})

	it('does not wait for a promise returned by page onLoad', async () => {
		let releaseOnLoad
		let initSettled = false
		const pageModule = new PageModule({
			onLoad() {
				return new Promise((resolve) => {
					releaseOnLoad = resolve
				})
			},
		}, {
			path: 'pages/async-lifecycle/index',
			usingComponents: {},
		})
		const page = new Page(pageModule, {
			bridgeId: 'bridge-async-page',
			moduleId: 'page-1',
			path: 'pages/async-lifecycle/index',
			query: {},
		})

		const initPromise = page.init().then(() => {
			initSettled = true
		})
		await Promise.resolve()
		await Promise.resolve()

		expect(initSettled).toBe(true)
		expect(page.initd).toBe(true)
		releaseOnLoad()
		await initPromise
	})

	it('runs custom component created, initial property observer, attached and ready in order', async () => {
		const calls = []
		const bridgeId = 'bridge-component-lifecycle'
		const module = new ComponentModule({
			properties: {
				value: {
					observer() {
						calls.push('property:observer')
					},
				},
			},
			lifetimes: {
				created() {
					calls.push('component:created')
				},
				attached() {
					calls.push('component:attached')
				},
				ready() {
					calls.push('component:ready')
				},
			},
			methods: {},
		}, {
			component: true,
			path: 'components/lifecycle/index',
			usingComponents: {},
		})
		const component = new Component(module, {
			bridgeId,
			moduleId: 'component-1',
			path: 'components/lifecycle/index',
			pageId: 'page-1',
			parentId: 'page-1',
			properties: { value: 'assigned' },
			propertyNames: ['value'],
			eventAttr: {},
			targetInfo: {},
		})
		runtime.instances[bridgeId] = { [component.__id__]: component }

		await component.init()
		runtime.moduleReady({ bridgeId, moduleId: component.__id__ })
		expect(calls).toEqual(['component:created', 'property:observer'])

		await runtime.moduleAttached({ bridgeId, moduleId: component.__id__ })
		expect(calls).toEqual([
			'component:created',
			'property:observer',
			'component:attached',
			'component:ready',
		])
	})

	it('does not wait for promises returned by component created and attached', async () => {
		const pendingLifecycles = []
		const module = new ComponentModule({
			lifetimes: {
				created() {
					return new Promise(resolve => pendingLifecycles.push(resolve))
				},
				attached() {
					return new Promise(resolve => pendingLifecycles.push(resolve))
				},
			},
			methods: {},
		}, {
			component: true,
			path: 'components/async-lifecycle/index',
			usingComponents: {},
		})
		const component = new Component(module, {
			bridgeId: 'bridge-async-component',
			moduleId: 'component-1',
			path: 'components/async-lifecycle/index',
			pageId: 'page-1',
			parentId: 'page-1',
			properties: {},
			propertyNames: [],
			eventAttr: {},
			targetInfo: {},
		})

		await component.init()
		await component.componentAttached()

		expect(component.initd).toBe(true)
		expect(pendingLifecycles).toHaveLength(2)
		pendingLifecycles.forEach(resolve => resolve())
	})

	it('queues child attached until its parent attaches and keeps child ready before parent ready', async () => {
		const calls = []
		const bridgeId = 'bridge-parent-child'
		const makeComponent = (id, parentId) => ({
			__id__: id,
			__parentId__: parentId,
			__type__: ComponentModule.type,
			__isComponent__: true,
			componentAttached: async () => calls.push(`${id}:attached`),
			componentReadied: () => calls.push(`${id}:ready`),
		})
		const parent = makeComponent('parent', 'page-1')
		const child = makeComponent('child', 'parent')
		runtime.instances[bridgeId] = { parent, child }

		await runtime.moduleAttached({ bridgeId, moduleId: child.__id__ })
		runtime.moduleReady({ bridgeId, moduleId: child.__id__ })
		runtime.moduleReady({ bridgeId, moduleId: parent.__id__ })
		expect(calls).toEqual([])

		await runtime.moduleAttached({ bridgeId, moduleId: parent.__id__ })
		expect(calls).toEqual([
			'parent:attached',
			'child:attached',
			'child:ready',
			'parent:ready',
		])
	})
})
