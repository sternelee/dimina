import { isFunction } from '@dimina/common'
import { App } from '../instance/app/app'
import { Component } from '../instance/component/component'
import { ComponentModule } from '../instance/component/component-module'
import { Page } from '../instance/page/page'
import { PageModule } from '../instance/page/page-module'
import loader from './loader'
import router from './router'

class Runtime {
	constructor() {
		this.app = null
		this.instances = {}
		this.pageStates = new Map()
	}

	getPageState(bridgeId) {
		if (!this.pageStates.has(bridgeId)) {
			this.pageStates.set(bridgeId, {
				hidden: false,
				pendingReady: false,
				pendingShow: false,
				ready: false,
				shown: false,
			})
		}
		return this.pageStates.get(bridgeId)
	}

	queuePendingEvent(instance, payload) {
		instance.__pendingRuntimeEvents__ = instance.__pendingRuntimeEvents__ || []
		return new Promise((resolve, reject) => {
			instance.__pendingRuntimeEvents__.push({
				...payload,
				resolve,
				reject,
			})
		})
	}

	async flushPendingEvents(instance) {
		const pendingEvents = instance?.__pendingRuntimeEvents__ || []
		instance.__pendingRuntimeEvents__ = []

		for (const pendingEvent of pendingEvents) {
			try {
				const result = await this.dispatchEvent(pendingEvent)
				pendingEvent.resolve(result)
			}
			catch (error) {
				pendingEvent.reject(error)
			}
		}
	}

	async dispatchEvent({ instance, bridgeId, moduleId, methodName, event }) {
		if (isFunction(instance[methodName])) {
			return await instance[methodName](event)
		}
		console.warn(`[service] triggerEvent ${bridgeId} ${moduleId}, is: ${instance.is}, method: ${methodName} is not exist`)
	}

	createApp(opts) {
		// app 实例只有一个，避免重复创建
		if (this.app) {
			console.log('[service] app instance already existed')
			return
		}

		const { scene, pagePath: path, query } = opts
		const appModule = loader.getAppModule()

		if (!appModule) {
			console.log('[service] app instance is not exist')
			return
		}

		console.log('[service] create app instance')

		this.app = new App(appModule, {
			scene,
			path,
			query,
		})
	}

	appShow() {
		this.app?.appShow()
	}

	appHide() {
		this.app?.appHide()
	}

	stackShow(stackId) {
		router.pushStack(stackId)
	}

	stackHide(stackId) {
		router.popStack(stackId)
	}

	/**
	 * 渲染层创建映射实例
	 * [Render]componentCreated -> [Container]createInstance ->[Service]createInstance
	 * @param {*} opts
	 */
	createInstance(opts) {
		const { bridgeId, moduleId, path, query, eventAttr, pageId, parentId, properties, propertyNames, targetInfo, stackId } = opts

		const module = loader.getModuleByPath(path)
		if (!module) {
			console.error(`[service] ${path} not exist`)
			return
		}

		console.log(`[service] create instance ${path}`)

		this.instances[bridgeId] = this.instances[bridgeId] || {}

		if (module.type === ComponentModule.type) {
			const component = new Component(module, {
				bridgeId,
				moduleId,
				path,
				query,
				eventAttr,
				pageId,
				parentId,
				properties,
				propertyNames,
				targetInfo,
			})
			this.instances[bridgeId][moduleId] = component
			if (!module.isComponent) {
				router.push(component, stackId)
			}
			component.init().then(() => {
				if (!module.isComponent && !this.getPageState(bridgeId).hidden) {
					this.pageShow({ bridgeId, moduleId })
				}
			})
			
			return component
		}
		else if (module.type === PageModule.type) {
			const page = new Page(module, {
				bridgeId,
				moduleId,
				path,
				query,
			})
			this.instances[bridgeId][moduleId] = page
			router.push(page, stackId)
			page.init().then(() => {
				if (!this.getPageState(bridgeId).hidden) {
					this.pageShow({ bridgeId, moduleId })
				}
			})
			return page
		}
		else {
			console.error(`[service] ${module.type} instance is not exist.`)
		}
	}

	async moduleAttached(opts) {
		const { bridgeId, moduleId } = opts
		const instance = this.instances[bridgeId]?.[moduleId]
		if (!instance || instance.__type__ !== ComponentModule.type || !instance.__isComponent__) {
			return
		}
		if (instance.__componentAttached__) {
			return instance.__attachPromise__
		}

		const parent = this.instances[bridgeId]?.[instance.__parentId__]
		if (parent?.__isComponent__ && !parent.__componentAttached__) {
			instance.__componentAttachPending__ = true
			return
		}
		if (instance.__attachPromise__) {
			return instance.__attachPromise__
		}

		instance.__componentAttachPending__ = false
		instance.__componentAttaching__ = true
		instance.__attachPromise__ = Promise.resolve(instance.componentAttached()).then(async () => {
			instance.__componentAttaching__ = false
			instance.__componentAttached__ = true
			if (this.getPageState(bridgeId).shown && !instance.__pageShown__) {
				instance.__pageShown__ = true
				instance.pageShow()
			}

			const children = Object.values(this.instances[bridgeId] || {}).filter(child => (
				child?.__parentId__ === moduleId && child.__componentAttachPending__
			))
			for (const child of children) {
				await this.moduleAttached({ bridgeId, moduleId: child.__id__ })
			}

			if (instance.__pendingReadyOpts__) {
				const pendingReadyOpts = instance.__pendingReadyOpts__
				delete instance.__pendingReadyOpts__
				this.moduleReady(pendingReadyOpts)
			}
		})
		return instance.__attachPromise__
	}

	moduleReady(opts) {
		const { bridgeId, moduleId, propBindings } = opts
		const instance = this.instances[bridgeId]?.[moduleId]

		if (!instance) {
			return
		}
		
		// 如果有属性绑定信息，注册到父组件
		if (propBindings && instance.__parentId__) {
			const parent = this.instances[bridgeId]?.[instance.__parentId__]
			if (parent) {
				if (!parent.__childPropsBindings__) {
					parent.__childPropsBindings__ = {}
				}
				// 将编译器提供的绑定关系存储到父组件
				parent.__childPropsBindings__[moduleId] = propBindings
			}
		}

		if (instance.__type__ === ComponentModule.type) {
			if (instance.__isComponent__ && !instance.__componentAttached__) {
				instance.__pendingReadyOpts__ = opts
				return
			}
			if (instance.__componentReadied__) {
				return
			}
			const pendingChildren = Object.values(this.instances[bridgeId] || {}).some(child => (
				child?.__isComponent__
				&& child.__componentAttached__
				&& !child.__componentReadied__
				&& this.isDescendantInstance(child, instance, bridgeId)
			))
			if (pendingChildren) {
				instance.__pendingReadyOpts__ = opts
				return
			}
			// 调用组件的 ready 生命周期
			instance.componentReadied()
			// 标记组件已准备就绪
			instance.__componentReadied__ = true
			this.flushPendingEvents(instance)
			instance.flushInitSetDataCallbacks?.()
			
			// 检查是否可以调用页面的 onReady
			const pageInstance = this.getPageInstance(bridgeId)
			if (pageInstance) {
				this.checkAndCallPageReady(bridgeId, pageInstance.__id__)
			}

			let parent = this.instances[bridgeId]?.[instance.__parentId__]
			while (parent?.__isComponent__) {
				if (parent.__pendingReadyOpts__) {
					const pendingReadyOpts = parent.__pendingReadyOpts__
					delete parent.__pendingReadyOpts__
					this.moduleReady(pendingReadyOpts)
				}
				parent = this.instances[bridgeId]?.[parent.__parentId__]
			}
		}
	}

	isDescendantInstance(candidate, ancestor, bridgeId) {
		let current = candidate
		while (current?.__parentId__) {
			if (current.__parentId__ === ancestor.__id__) {
				return true
			}
			current = this.instances[bridgeId]?.[current.__parentId__]
		}
		return false
	}

	moduleUnmounted(opts) {
		const { bridgeId, moduleId } = opts
		const instance = this.instances[bridgeId]?.[moduleId]

		if (!instance) {
			return
		}

		if (instance.__type__ === ComponentModule.type) {
			if ((!instance.__isComponent__ || instance.__componentAttached__) && !instance.__componentDetached__) {
				instance.componentDetached()
				instance.__componentDetached__ = true
			}
		}
		delete this.instances[bridgeId][moduleId]
	}

	pageShow(opts) {
		const { bridgeId } = opts
		const state = this.getPageState(bridgeId)
		state.hidden = false
		state.pendingShow = true
		const instances = this.instances[bridgeId]

		// 首次进入时模块可能不存在
		if (!instances) {
			return
		}
		const pageInstance = this.getPageInstance(bridgeId)
		if (!pageInstance?.initd) {
			return
		}
		if (state.shown) {
			state.pendingShow = false
			return
		}
		state.shown = true
		state.pendingShow = false

		const pageInstances = []

		const orderedInstances = Object.values(instances)
			.sort((left, right) => this.getInstanceDepth(left, bridgeId) - this.getInstanceDepth(right, bridgeId))

		orderedInstances.forEach((instance) => {
			if (!instance) {
				return
			}
			if (instance.__type__ === PageModule.type) {
				pageInstances.push(instance)
			}
			else if (instance.__type__ === ComponentModule.type) {
				if (!instance.__isComponent__) {
					pageInstances.push(instance)
				}
				else if (instance.__componentAttached__ && !instance.__pageShown__) {
					instance.__pageShown__ = true
					instance.pageShow()
				}
			}
		})

		// 在循环结束后，统一调用页面的 pageShow 方法
		pageInstances.forEach((instance) => {
			instance.pageShow()
		})

		if (state.pendingReady) {
			this.pageReady({ ...opts, moduleId: pageInstance.__id__ })
		}
	}

	pageReady(opts) {
		const { bridgeId, moduleId } = opts
		const state = this.getPageState(bridgeId)
		state.pendingReady = true
		const instance = this.instances[bridgeId]?.[moduleId]

		if (!instance) {
			return
		}

		if (!state.shown) {
			this.pageShow(opts)
		}
		if (!state.shown || state.ready) {
			return
		}
		
		// 标记页面准备就绪，但延迟调用 onReady
		// 等待所有组件的 ready 执行完毕后再调用
		instance.__pageReadyPending__ = true
		instance.flushInitSetDataCallbacks?.()
		
		// 检查是否所有组件都已经准备就绪
		this.checkAndCallPageReady(bridgeId, moduleId)
	}

	/**
	 * 检查并调用页面的 onReady
	 * 确保所有组件的 ready 都已执行完毕
	 */
	/**
	 * 获取指定 bridgeId 下的页面实例
	 */
	getPageInstance(bridgeId) {
		const instances = this.instances[bridgeId]
		if (!instances) {
			return null
		}

		return Object.values(instances).find(instance => {
			return instance && (
				instance.__type__ === PageModule.type || 
				(instance.__type__ === ComponentModule.type && !instance.__isComponent__)
			)
		})
	}

	checkAndCallPageReady(bridgeId, moduleId) {
		const state = this.getPageState(bridgeId)
		const instance = this.instances[bridgeId]?.[moduleId]
		if (!instance || !instance.__pageReadyPending__ || !state.shown || state.ready) {
			return
		}

		const instances = this.instances[bridgeId]
		if (!instances) {
			// 没有组件，直接调用页面 onReady
			instance.__pageReadyPending__ = false
			state.pendingReady = false
			state.ready = true
			instance.pageReady()
			return
		}

		// 检查是否还有组件未准备就绪
		const pendingComponents = Object.values(instances).filter(componentInstance => {
			return componentInstance && 
				componentInstance.__type__ === ComponentModule.type && 
				componentInstance.__isComponent__ &&
				componentInstance.initd &&
				!componentInstance.__componentReadied__
		})

		if (pendingComponents.length === 0) {
			// 所有组件都已准备就绪，调用页面 onReady
			instance.__pageReadyPending__ = false
			state.pendingReady = false
			state.ready = true
			instance.pageReady()
		}
	}

	pageHide(opts) {
		const { bridgeId } = opts
		const state = this.getPageState(bridgeId)
		state.hidden = true
		state.pendingShow = false
		if (!state.shown) {
			return
		}
		state.shown = false
		const instances = this.instances[bridgeId]
		if (!instances) {
			return
		}

		const pageInstances = []

		const orderedInstances = Object.values(instances)
			.sort((left, right) => this.getInstanceDepth(left, bridgeId) - this.getInstanceDepth(right, bridgeId))

		orderedInstances.forEach((instance) => {
			if (!instance) {
				return
			}
			if (instance.__type__ === PageModule.type) {
				pageInstances.push(instance)
			}
			else if (instance.__type__ === ComponentModule.type) {
				if (!instance.__isComponent__) {
					pageInstances.push(instance)
				}
				else if (instance.__componentAttached__ && instance.__pageShown__) {
					instance.__pageShown__ = false
					instance.pageHide()
				}
			}
		})

		// 在循环结束后，统一调用页面的 pageHide 方法
		pageInstances.forEach((instance) => {
			if (!instance) {
				return
			}
			instance.pageHide()
		})
	}

	pageUnload(opts) {
		const { bridgeId } = opts
		const instances = this.instances[bridgeId]

		if (!instances) {
			return
		}

		const instanceList = Object.values(instances)
		const customComponents = instanceList
			.filter(instance => instance?.__type__ === ComponentModule.type && instance.__isComponent__)
			.sort((left, right) => this.getInstanceDepth(right, bridgeId) - this.getInstanceDepth(left, bridgeId))

		customComponents.forEach((instance) => {
			if (instance.__componentAttached__ && !instance.__componentDetached__) {
				instance.componentDetached()
				instance.__componentDetached__ = true
			}
		})

		instanceList.forEach((instance) => {
			if (!instance) {
				return
			}
			if (instance.__type__ === ComponentModule.type && !instance.__isComponent__ && !instance.__componentDetached__) {
				instance.componentDetached()
				instance.__componentDetached__ = true
			}
			instance.pageUnload()
		})

		router.pop()

		delete this.instances[bridgeId]
		this.pageStates.delete(bridgeId)
	}

	getInstanceDepth(instance, bridgeId) {
		let depth = 0
		let current = instance
		while (current?.__parentId__) {
			depth++
			current = this.instances[bridgeId]?.[current.__parentId__]
		}
		return depth
	}

	pageScroll(opts) {
		const { bridgeId, moduleId, scrollTop } = opts
		const instance = this.instances[bridgeId]?.[moduleId]

		if (!instance) {
			return
		}
		instance.pageScrollTop({ scrollTop })
	}

	pageResize(opts) {
		const { bridgeId, size } = opts
		const instances = this.instances[bridgeId]

		if (!instances) {
			return
		}

		const pageInstances = []
		const orderedInstances = Object.values(instances)
			.sort((left, right) => this.getInstanceDepth(left, bridgeId) - this.getInstanceDepth(right, bridgeId))

		orderedInstances.forEach((instance) => {
			if (!instance) {
				return
			}
			if (instance.__type__ === PageModule.type) {
				pageInstances.push(instance)
			}
			else if (instance.__type__ === ComponentModule.type) {
				if (!instance.__isComponent__) {
					pageInstances.push(instance)
				}
				else if (instance.__componentAttached__) {
					instance.pageResize(size)
				}
			}
		})

		pageInstances.forEach(instance => instance.pageResize(size))
	}

	componentError(opts) {
		const { bridgeId, moduleId } = opts
		const instance = this.instances[bridgeId]?.[moduleId]

		if (!instance) {
			return
		}

		if (instance.__type__ === ComponentModule.type) {
			instance.componentError()
		}
	}

	componentRouteDone(opts) {
		const { bridgeId } = opts
		const instances = this.instances[bridgeId]

		if (!instances) {
			return
		}

		Object.values(instances)
			.sort((left, right) => this.getInstanceDepth(left, bridgeId) - this.getInstanceDepth(right, bridgeId))
			.forEach((instance) => {
				if (instance?.__type__ === ComponentModule.type && (!instance.__isComponent__ || instance.__componentAttached__)) {
					instance.componentRouteDone()
				}
			})
	}

	/**
	 * 调用业务 js 方法
	 * @param {*} opts
	 */
	async triggerEvent(opts) {
		const { bridgeId, moduleId, methodName, event } = opts

		if (methodName === undefined) {
			return
		}

		const instances = this.instances[bridgeId]
		if (!instances) {
			console.warn(`[service] No instances found for bridgeId: ${bridgeId}`)
			return
		}

		const instance = instances[moduleId]
		if (!instance) {
			console.warn(`[service] triggerEvent ${bridgeId} ${moduleId} ${methodName}, instance is not exist`)
			return
		}

		if (
			instance.__type__ === ComponentModule.type
			&& instance.__isComponent__
			&& !instance.__componentReadied__
		) {
			return this.queuePendingEvent(instance, {
				instance,
				bridgeId,
				moduleId,
				methodName,
				event,
			})
		}

		return this.dispatchEvent({
			instance,
			bridgeId,
			moduleId,
			methodName,
			event,
		})
	}
}

export default new Runtime()
