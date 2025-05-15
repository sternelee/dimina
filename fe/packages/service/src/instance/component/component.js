import { cloneDeep, isFunction, isString, set } from '@dimina/common'
import message from '../../core/message'
import runtime from '../../core/runtime'
import { addComputedData, filterData, filterInvokeObserver, isChildComponent, matchComponent } from '../../core/utils'
import { createSelectorQuery } from '../../api/core/wxml/selector-query'

// 组件生命周期
const componentLifetimes = ['created', 'attached', 'ready', 'moved', 'detached', 'error']
// 组件所在页面的生命周期
const pageLifetimes = ['show', 'hide', 'resize', 'routeDone']

/**
 * https://developers.weixin.qq.com/miniprogram/dev/reference/api/Component.html
 */
export class Component {
	constructor(module, opts) {
		this.initd = false
		this.opts = opts
		if (opts.targetInfo) {
			this.id = opts.targetInfo.id
			this.dataset = opts.targetInfo.dataset
			this.__targetInfo__ = opts.targetInfo
		}
		this.is = opts.path
		this.renderer = 'webview'
		this.bridgeId = opts.bridgeId
		this.behaviors = module.behaviors
		this.data = cloneDeep(module.noReferenceData)
		this.__isComponent__ = module.isComponent
		this.__type__ = module.type
		this.__id__ = this.opts.moduleId
		this.__info__ = module.moduleInfo
		this.__eventAttr__ = opts.eventAttr
		this.__pageId__ = opts.pageId
		this.__parentId__ = opts.parentId

		this.#init()
	}

	#init() {
		if (this.__isComponent__) {
			for (const key in this.__info__.properties) {
				// 先取逻辑层的属性默认值
				if (!Object.prototype.hasOwnProperty.call(this.opts.properties, key) || this.opts.properties[key] === undefined) {
					this.data[key] = this.__info__.properties[key].value
				}
				else {
					// 没有默认值则取渲染层的属性实际值
					this.data[key] = this.opts.properties[key]
				}
			}
		}

		this.#initLifecycle()
		this.#initCustomMethods()
		this.#invokeInitLifecycle().then(() => {
			addComputedData(this)
			message.send({
				type: this.__id__,
				target: 'render',
				body: {
					bridgeId: this.bridgeId,
					path: this.is,
					data: this.data,
				},
			})
		})
	}

	/**
	 * https://developers.weixin.qq.com/miniprogram/dev/framework/performance/tips/runtime_setData.html
	 * @param {*} data
	 */
	setData(data) {
		const fData = filterData(data)
		for (const key in fData) {
			set(this.data, key, fData[key])
		}

		if (!this.initd) {
			return
		}

		message.send({
			type: 'u',
			target: 'render',
			body: {
				bridgeId: this.bridgeId,
				moduleId: this.__id__,
				data: fData,
			},
		})
	}

	/**
	 * https://developers.weixin.qq.com/miniprogram/dev/framework/custom-component/lifetimes.html
	 */
	#initLifecycle() {
		componentLifetimes.forEach((method) => {
			const lifecycleMethod = this.__info__.lifetimes?.[method] || this.__info__[method]
			if (!isFunction(lifecycleMethod)) {
				return
			}
			this[method] = lifecycleMethod.bind(this)
		})
		if (this.__isComponent__) {
			pageLifetimes.forEach((method) => {
				const lifecycleMethod = this.__info__.pageLifetimes?.[method]
				if (!isFunction(lifecycleMethod)) {
					return
				}
				if (method === 'show') {
					method = 'onShow'
				}
				else if (method === 'hide') {
					method = 'onHide'
				}
				this[method] = lifecycleMethod.bind(this)
			})
		}
	}

	/**
	 * 开发者自定义函数
	 * Component 构造器的主要区别是：方法需要放在 methods: { } 里面
	 */
	#initCustomMethods() {
		const methods = this.__info__.methods
		for (const attr in methods) {
			if (isFunction(methods[attr])) {
				this[attr] = methods[attr].bind(this)
			}
		}
	}

	async #invokeInitLifecycle() {
		if (this.__isComponent__) {
			await this.componentCreated()
			await this.componentAttached()
		}
		else {
			// 使用 Component 构造器创建的页面生命周期
			await this.componentCreated()
			await this.componentAttached()

			await this.onLoad?.(this.opts.query || {})
		}
		this.initd = true
	}

	/**
	 * 触发观察者函数
	 * triggerObserver
	 */
	tO(data) {
		for (const [prop, val] of Object.entries(data)) {
			if (this.__info__.observers) {
				filterInvokeObserver(prop, this.__info__.observers, data, this)
			}

			const observer = this.__info__.properties[prop]?.observer

			if (isString(observer)) {
				this[observer]?.(val)
			}
			else if (isFunction(observer)) {
				observer.call(this, val)
			}
		}
	}

	getPageId() {
		return this.__id__
	}

	/**
	 * 检查组件是否具有 behavior （检查时会递归检查被直接或间接引入的所有behavior）
	 * https://developers.weixin.qq.com/miniprogram/dev/framework/custom-component/behaviors.html
	 */
	hasBehavior(behavior) {
		const _hasBehavior = function (behaviors) {
			if (behaviors.includes(behavior)) {
				return true
			}
			for (const b of behaviors) {
				if (_hasBehavior(b.behaviors)) {
					return true
				}
			}

			return false
		}
		return _hasBehavior(this.behaviors)
	}

	/**
	 * 创建一个 SelectorQuery 对象，选择器选取范围为这个组件实例内
	 */
	createSelectorQuery() {
		return createSelectorQuery().in(this)
	}

	/**
	 * 使用选择器选取子组件实例对象，返回匹配到的第一个组件实例对象
	 */
	selectComponent(selector) {
		const children = Object.values(runtime.instances[this.bridgeId])

		// 遍历所有组件查找匹配的子组件
		return children.find(item =>
			isChildComponent(item, this.__id__, children) && matchComponent(selector, item),
		) || null
	}

	/**
	 * 使用选择器选取子组件实例对象，返回匹配到的全部组件实例对象组成的数组
	 */
	selectAllComponents(selector) {
		const children = Object.values(runtime.instances[this.bridgeId])

		// 遍历所有组件查找匹配的子组件
		return children.filter(item =>
			isChildComponent(item, this.__id__, children) && matchComponent(selector, item),
		)
	}

	/**
	 * 选取当前组件节点所在的组件实例（即组件的引用者），返回它的组件实例对象
	 */
	selectOwnerComponent() {
		const children = Object.values(runtime.instances[this.bridgeId])
		for (const item of children) {
			if (item.id === this.__parentId__) {
				return item
			}
		}
		return null
	}

	/**
	 * TODO: 创建一个 IntersectionObserver 对象，选择器选取范围为这个组件实例内
	 */
	createIntersectionObserver() {
		console.warn('[service] 暂不支持 createIntersectionObserver')
	}

	/**
	 * TODO: 创建一个 MediaQueryObserver 对象
	 */
	createMediaQueryObserver() {
		console.warn('[service] 暂不支持 createMediaQueryObserver')
	}

	/**
	 * TODO: 获取这个关系所对应的所有关联节点
	 */
	getRelationNodes() {
		console.warn('[service] 暂不支持 getRelationNodes')
	}

	/**
	 * TODO: 执行关键帧动画
	 */
	animate() {
		console.warn('[service] 暂不支持 animate')
	}

	/**
	 * TODO: 清除关键帧动画
	 */
	clearAnimation() {
		console.warn('[service] 暂不支持 clearAnimation')
	}

	/**
	 * 触发组件所在页面的事件逻辑
	 * https://developers.weixin.qq.com/miniprogram/dev/framework/custom-component/events.html
	 * @param {*} methodName
	 * @param {*} detail // detail���象，提供给事件监听函数
	 * @param {*} options // 触发事件的选项
	 */
	async triggerEvent(methodName, detail, options = {}) {
		const type = methodName.trim()
		await runtime.triggerEvent({
			bridgeId: this.bridgeId,
			moduleId: this.__pageId__,
			methodName: this.__eventAttr__[type],
			event: {
				type,
				detail,
				currentTarget: {
					id: this.id,
					dataset: this.dataset,
				},
				target: {
					id: this.id,
					dataset: this.dataset,
				},
			},
		})

		// 事件是否冒泡
		if (options.bubbles) {
			// 当前组件的上一级自定义组件
			const parentInstance = runtime.instances[this.bridgeId][this.__parentId__]
			await parentInstance?.triggerEvent(methodName, detail)
		}

		// 事件是否可以穿越组件边界，为false时，事件将只能在引用组件的节点树上触发，不进入其他任何组件内部
		if (options.composed) {
			// TODO:当前组件的上一级自定义组件的内部
		}

		if (options.capturePhase) {
			// TODO:事件是否拥有捕获阶段
		}
	}

	pageReady() {
		if (!this.__isComponent__) {
			this.ready?.()
		}
	}

	/**
	 * 页面退出时执行
	 */
	pageUnload() {
		if (!this.__isComponent__) {
			this.onUnload?.()
		}
	}

	pageScrollTop(opts) {
		if (!this.__isComponent__) {
			const { scrollTop } = opts
			this.onPageScroll?.({ scrollTop })
		}
	}

	// --- 组件所在页面的生命周期 ---
	/**
	 * 组件所在的页面被展示时执行
	 */
	pageShow() {
		this.onShow?.()
	}

	/**
	 * 组件所在的页面被隐藏时执行
	 */
	pageHide() {
		this.onHide?.()
	}

	/**
	 * 组件所在的页面尺寸变化时执行
	 * @param {object} size
	 */
	pageResize(size) {
		this.resize?.(size)
	}

	// 组件所在页面路由动画完成时执行
	componentRouteDone() {
		this.routeDone?.()
	}

	// --- 组件的生命周期 ---
	/**
	 * 在组件实例刚刚被创建时执行
	 */
	async componentCreated() {
		this.__info__.behaviorLifetimes?.created?.forEach(method => method.call(this))
		await this.created?.()
	}

	/**
	 * 在组件实例进入页面节点树时执行
	 */
	async componentAttached() {
		this.__info__.behaviorLifetimes?.attached?.forEach(method => method.call(this))
		await this.attached?.()
	}

	/**
	 * 在组件在视图层布局完成后执行
	 */
	componentReadied() {
		this.__info__.behaviorLifetimes?.ready?.forEach(method => method.call(this))
		this.ready?.()
	}

	/**
	 * 在组件实例被���动到节点树另一个位置时执行
	 */
	componentMoved() {
		this.moved?.()
	}

	/**
	 * 在组件实例被从页面节点树移除时执行
	 */
	componentDetached() {
		this.__info__.behaviorLifetimes?.detached?.forEach(method => method.call(this))
		this.detached?.()
		this.initd = false
	}

	/**
	 * 每当组件方法抛出错误时执行
	 * @param {*} error
	 */
	componentError(error) {
		this.error?.(error)
	}
}
