import {
	Fragment,
	Suspense,
	createApp,
	createBlock,
	createCommentVNode,
	createElementBlock,
	createElementVNode,
	createSlots,
	createTextVNode,
	createVNode,
	getCurrentInstance,
	h,
	inject,
	nextTick,
	normalizeClass,
	normalizeStyle,
	onMounted,
	onUnmounted,
	openBlock,
	provide,
	reactive,
	ref,
	renderList,
	renderSlot,
	resolveComponent,
	resolveDirective,
	resolveDynamicComponent,
	toDisplayString,
	watch,
	withCtx,
	withDirectives,
} from 'vue'
import { Components, deepToRaw, triggerEvent } from '@dimina/components'
import { getDataAttributes, set, uuid } from '@dimina/common'
import loader from './loader'
import message from './message'

class Runtime {
	constructor() {
		this.app = null
		this.pageId = null
		this.instance = new Map()
		this.intersectionObservers = new Map()

		window._Fragment = Fragment
		window._createTextVNode = createTextVNode
		window._createVNode = createVNode
		window._createBlock = createBlock
		window._createCommentVNode = createCommentVNode
		window._createElementBlock = createElementBlock
		window._createElementVNode = createElementVNode
		window._createSlots = createSlots
		window._normalizeClass = normalizeClass
		window._normalizeStyle = normalizeStyle
		window._openBlock = openBlock
		window._renderList = renderList
		window._renderSlot = renderSlot
		window._resolveComponent = resolveComponent
		window._resolveDirective = resolveDirective
		window._resolveDynamicComponent = resolveDynamicComponent
		window._toDisplayString = toDisplayString
		window._withCtx = withCtx
		window._withDirectives = withDirectives

		window.addEventListener('beforeunload', () => {
			if (this.intersectionObservers.size > 0) {
				for (const observers of this.intersectionObservers.values()) {
					observers.forEach(observer => observer.disconnect())
				}
				this.intersectionObservers.clear()
			}
		})
	}

	/**
	 * 首次渲染
	 * [Container] resourceLoaded -> [Service] firstRender -> [Render] firstRender
	 * @param {*} opts
	 */
	firstRender(opts) {
		const { bridgeId, pagePath, pageId, query } = opts

		const options = this.makeOptions({
			path: pagePath,
			bridgeId,
			pageId,
			query,
		})

		if (this.app != null) {
			this.app.unmount()
		}
		this.app = createApp(options.app)
		// 全量加载基础组件，是否有必要可优化为按需加载组件
		this.app.use(Components)

		// 注册页面模板
		for (const [tplName, render] of Object.entries(options.tplComponents)) {
			this.app.component(`dd-${tplName}`, {
				__scopeId: `data-v-${options.id}`,
				props: {
					data: Object,
				},
				data() {
					return {
						...this.data,
					}
				},
				render,
			})
		}

		this.app.mount(document.body)
	}

	// Component create -> Page create -> Page attached -> Component attached -> Component ready -> Page ready
	// Component attached -> Page onLoad -> Page onShow -> Component ready -> onReady
	makeOptions(opts) {
		const { path, bridgeId, pageId } = opts
		const pageModule = loader.getModuleByPath(path)
		const { id, usingComponents, tplComponents } = pageModule.moduleInfo
		this.pageId = pageId
		const components = this.createComponent(path, bridgeId, usingComponents)
		const self = this
		const rootCom = 'dd-page'
		const sId = `data-v-${id}`
		return {
			id,
			tplComponents,
			app: {
				render: () => {
					const _component_dd_page = resolveComponent(rootCom)
					return h(Suspense, {
						onResolve: () => {
							message.invoke({
								type: 'domReady',
								target: 'container',
								body: {
									bridgeId,
								},
							})
						},
					}, {
						default: () => h(_component_dd_page, { class: 'dd-page' }),
						// fallback: () => h('div', 'Loading...'),
					})
				},
				components: {
					[rootCom]: {
						__scopeId: sId,
						async setup(_props, { expose }) {
							expose()
							provide('bridgeId', bridgeId)
							provide('path', path)
							provide(path, {
								id: self.pageId,
							})
							provide('info', {
								id: self.pageId,
								sId,
							})

							const instance = getCurrentInstance().proxy
							instance.__page__ = true
							self.instance.set(self.pageId, instance)

							let ticking = false
							const handleScroll = () => {
								if (!ticking) {
									window.requestAnimationFrame(() => {
										message.send({
											type: 'pageScroll',
											target: 'service',
											body: {
												bridgeId,
												moduleId: self.pageId,
												scrollTop: window.scrollY,
											},
										})
										ticking = false
									})
									ticking = true
								}
							}

							onMounted(() => {
								window.addEventListener('scroll', handleScroll, { passive: true })
								nextTick(() => {
									message.send({
										type: 'pageReady',
										target: 'service',
										body: {
											bridgeId,
											moduleId: self.pageId,
										},
									})
								})
							})

							onUnmounted(() => {
								window.removeEventListener('scroll', handleScroll)
							})

							const data = reactive({})
							const initData = await message.wait(self.pageId)
							const entries = Object.entries(initData)
							for (let i = 0; i < entries.length; i++) {
								const [key, value] = entries[i]
								set(data, key, value)
							}
							return data
						},
						components,
						render: pageModule.moduleInfo.render,
					},
				},

			},
		}
	}

	createComponent(path, bridgeId, usingComponents) {
		if (!usingComponents || Object.keys(usingComponents).length === 0) {
			return
		}

		const components = {}
		const self = this
		for (const [componentName, componentPath] of Object.entries(usingComponents)) {
			const module = loader.getModuleByPath(componentPath)
			const { id, usingComponents: subUsing } = module.moduleInfo
			const subComponents = this.createComponent(componentPath, bridgeId, subUsing)
			const sId = `data-v-${id}`

			// setup -> beforeCreate -> beforeMount
			components[`dd-${componentName}`] = {
				__scopeId: sId,
				components: subComponents,
				props: module.props,
				async setup(props, { attrs, expose }) {
					const parentInfo = inject('info')

					expose({
						props,
						sId: parentInfo.sId,
					})
					const parentId = parentInfo.id
					const pageInfo = inject(path)
					const pageId = pageInfo.id
					const moduleId = `${id}_${uuid()}`
					provide('info', {
						id: moduleId,
						sId,
					})
					provide('path', componentPath)
					provide(componentPath, {
						id: moduleId,
						pagePath: path, // 引入该组件的页面信息
						pageId,
					})

					const instance = getCurrentInstance().proxy
					self.instance.set(moduleId, instance)

					for (const v of Object.values(module.props ?? {})) {
						if (v.cls) {
							// 自定义组件的外部样式类，通过 v-c-class 自定义指令处理
							provide('externalClass', true)
							break
						}
					}

					const eventAttr = {}
					for (const attrName in attrs) {
						if (attrName.startsWith('bind') || attrName.startsWith('catch')) {
							eventAttr[attrName.replace(/^(?:bind:|bind|catch:|catch)/, '')] = attrs[attrName]
						}
					}

					watch(
						props,
						(newProps) => {
							message.send({
								type: 't',
								target: 'service',
								body: {
									bridgeId,
									moduleId,
									methodName: 'tO', // triggerObserver
									event: deepToRaw(newProps),
								},
							})
						},
					)

					message.send({
						type: 'mC', // createInstance
						target: 'service',
						body: {
							bridgeId,
							moduleId,
							path: componentPath,
							pageId,
							parentId,
							eventAttr,
							targetInfo: {
								dataset: getDataAttributes(attrs, deepToRaw),
								id: attrs.id,
								class: attrs.class,
							},
							properties: deepToRaw(props),
						},
					})

					onMounted(() => {
						nextTick(() => {
							message.send({
								type: 'mR',
								target: 'service',
								body: {
									bridgeId,
									moduleId,
								},
							})
						})
						// 自定义组件上绑定了点击事件
						if (eventAttr.tap) {
							instance.$el.addEventListener('click', (event) => {
								triggerEvent('tap', {
									event,
									info: {
										attrs,
										bridgeId,
										moduleId: pageId,
									},
								})
							})
						}
					})

					onUnmounted(() => {
						message.send({
							type: 'mU',
							target: 'service',
							body: {
								bridgeId,
								moduleId,
							},
						})
						self.instance.delete(moduleId)
					})

					const data = reactive({})
					const initData = await message.wait(moduleId)
					const entries = Object.entries(initData)
					for (let i = 0; i < entries.length; i++) {
						const [key, value] = entries[i]
						if (!(module.props && Object.prototype.hasOwnProperty.call(module.props, key))) {
							set(data, key, value)
						}
					}
					return data
				},
				render: module.moduleInfo.render,
			}
		}
		return components
	}

	updateModule(opts) {
		const { moduleId, data } = opts
		const viewModule = this.instance.get(moduleId)

		if (viewModule) {
			for (const key in data) {
				viewModule.$nextTick(() => {
					// 检查属性是否已经存在于组件上
					if (!key.includes('.') && !key.includes('[') && !(key in viewModule)) {
						const refValue = ref(data[key])
						Object.defineProperty(viewModule, key, {
							get() {
								return refValue.value
							},
							set(newValue) {
								refValue.value = newValue
							},
							enumerable: true,
							configurable: true,
						})
					}
					else {
						// 如果属性已存在，直接设置新值
						set(viewModule, key, data[key])
					}
				})
			}
		}
		else {
			console.warn(`[Render] module ${moduleId} is not exist.`)
		}
	}

	async waitForEl(instance, timeout = 500) {
		if (!instance) {
			return
		}
		if (instance.__page__) {
			return document.body
		}
		const el = instance.$el
		if (el) {
			return el
		}

		return new Promise((resolve) => {
			const observer = new MutationObserver((_, obs) => {
				const el = instance.$el
				if (el) {
					obs.disconnect() // 停止观察
					resolve(el)
				}
			})

			if (instance.$parent.$el?.nodeType === Node.COMMENT_NODE) {
				observer.observe(document.body, { childList: true, subtree: true })
			}
			else {
				observer.observe(instance.$parent.$el, { childList: true })
			}

			// 设置超时处理
			setTimeout(() => {
				observer.disconnect() // 超时后停止观察
				resolve()
			}, timeout)
		})
	}

	async waitForElement(parent, selector, method, timeout = 500) {
		if (!parent[method]) {
			console.warn(`[Render] waitForElement method ${method} in ${parent.nodeType}`)
			return null
		}
		const elements = parent[method](selector)
		if (elements) {
			return elements
		}
		return new Promise((resolve) => {
			const observer = new MutationObserver((_, obs) => {
				const elements = parent[method](selector)
				if (elements) {
					obs.disconnect()
					resolve(elements)
				}
			})

			observer.observe(parent, { childList: true, subtree: true })

			setTimeout(() => {
				observer.disconnect()
				resolve()
			}, timeout)
		})
	}

	selectorQuery(opts) {
		setTimeout(async () => {
			const { bridgeId, params: { tasks, success } } = opts

			const results = await Promise.all(tasks.map(async (task) => {
				const { moduleId, selector, single, fields } = task
				const el = await this.waitForEl(this.instance.get(moduleId))
				if (!el) {
					console.warn(`[Render] module ${moduleId} dom is not exist.`)
					return null
				}

				if (!el.querySelector) {
					console.warn(`[Render] selectorQuery el node type is ${el.nodeType}`)
					return null
				}

				const selectors = selector.split(',').map(s => `${s.trim()}:not([data-dd-cloned] *)`).join(',')
				if (single) {
					// 排除任何带有 data-dd-cloned 属性的父元素的子元素
					const targetElement = el.querySelector(selectors)
					return targetElement ? this.parseElement(targetElement, fields) : null
				}
				else {
					// 排除带有 data-dd-cloned 属性的元素
					const targetElements = el.querySelectorAll(selectors)
					return Array.from(targetElements).map(el => this.parseElement(el, fields))
				}
			}))

			const res = results.filter(Boolean)

			message.send({
				type: 'triggerCallback',
				target: 'service',
				body: {
					bridgeId,
					id: success,
					args: res,
				},
			})
		// 延迟为了解决获取元素高度为 0 导致异常
		}, 300)
	}

	parseElement(targetElement, fields) {
		const data = {}

		if (fields.dataset) {
			data.dataset = targetElement._ds
		}
		if (fields.rect) {
			const { left, top, right, bottom, width, height } = targetElement.getBoundingClientRect()
			data.left = left
			data.top = top
			data.right = right
			data.bottom = bottom
			data.width = width
			data.height = height
		}

		data.id = targetElement.id ?? ''

		if (fields.scrollOffset) {
			data.scrollHeight = targetElement.scrollHeight
			data.scrollLeft = targetElement.scrollLeft
			data.scrollTop = targetElement.scrollTop
			data.scrollWidth = targetElement.scrollWidth
		}

		// TODO: 支持获取 Canvas 和 ScrollViewContext
		// if (fields.node) {
		// }
		// TODO: 支持获取 VideoContext、CanvasContext、LivePlayerContext、EditorContext和 MapContext
		// if (fields.context) {
		// }

		return data
	}

	showToast({ params }) {
		window.__globalAPI.showToast(params)
	}

	hideToast({ params }) {
		window.__globalAPI.hideToast(params)
	}

	addIntersectionObserver(opts) {
		setTimeout(async () => {
			const { bridgeId, params: { targetSelector, relativeInfo, moduleId, options, success } } = opts

			const el = await this.waitForEl(this.instance.get(moduleId))
			if (!el) {
				console.error('[Render] Failed to find element for intersection observer')
				return
			}
			// 创建所有参考区域的观察器配置
			const observers = []
			for (const info of relativeInfo) {
				const observerOptions = {
					root: null,
					threshold: options.thresholds,
					rootMargin: info.margins,
					initialRatio: options.initialRatio,
					observeAll: options.observeAll,
				}

				if (info.selector === null) {
					// viewport 情况
					observerOptions.root = null
					observers.push({ options: observerOptions })
					continue
				}

				// relativeTo 情况
				const relativeEl = await this.waitForElement(el, info.selector, 'querySelector')
				const targetEls = await this.waitForElement(el, targetSelector, options.observeAll ? 'querySelectorAll' : 'querySelector')

				if (!relativeEl || !targetEls) {
					console.warn(`[Render] Failed to find elements`)
					continue
				}

				// 检查是否为祖先关系
				const isAncestor = Array.isArray(targetEls)
					? Array.from(targetEls).some(target => relativeEl.contains(target))
					: relativeEl.contains(targetEls)

				if (isAncestor) {
					// 祖先元素关系，使用标准设置
					observerOptions.root = relativeEl
				}
				else {
					const position = window.getComputedStyle(relativeEl).position
					if (position === 'fixed') {
						// 非祖先关系，且是固定元素，使用 rootMargin 模拟，getBoundingClientRect()或由于祖先的 transform 数据错误
						const computedStyle = window.getComputedStyle(relativeEl)
						const top = Number.parseFloat(computedStyle.top) || 0
						const bottom = top + Number.parseFloat(computedStyle.height) || 0
						const left = Number.parseFloat(computedStyle.left) || 0
						const right = left + Number.parseFloat(computedStyle.width) || 0
						// 计算相对于视口的边距
						observerOptions.root = null
						observerOptions.type = 'fixed'
						observerOptions.rootMargin = `${-top}px ${-(window.innerWidth - right)}px ${-(window.innerHeight - bottom)}px ${-left}px`
					}
					else {
						continue
					}
				}

				observers.push({ options: observerOptions })
			}

			const targetEls = await this.waitForElement(el, targetSelector, options.observeAll ? 'querySelectorAll' : 'querySelector')
			if (!targetEls) {
				console.error('[Render] Failed to find target element for intersection observer')
				return
			}

			const allObservers = observers.map(({ options }) => {
				let initRatio = options.initialRatio
				const observer = new IntersectionObserver((entries) => {
					entries.forEach((entry) => {
						if (entry.intersectionRatio === initRatio)
							return
						initRatio = entry.intersectionRatio
						// 检查元素是否真的离开视口
						const { top, bottom } = entry.boundingClientRect
						const viewportHeight = window.innerHeight

						// 如果元素还在视口范围内，则不触发回调
						if (!options.type && !entry.isIntersecting
							&& top >= 0
							&& bottom <= viewportHeight) {
							return
						}

						message.send({
							type: 'triggerCallback',
							target: 'service',
							body: {
								bridgeId,
								id: success,
								args: {
									info: {
										boundingClientRect: entry.boundingClientRect, // 目标边界
										intersectionRatio: entry.intersectionRatio, // 相交比例
										intersectionRect: entry.intersectionRect, // 相交区域的边界
										relativeRect: entry.rootBounds, // 相对参考区域
										time: entry.time,
									},
								},
							},
						})
					})
				}, options)

				if (options.observeAll) {
					Array.from(targetEls).forEach(target => observer.observe(target))
				}
				else {
					observer.observe(targetEls)
				}

				return observer
			})

			const observerId = uuid()
			this.intersectionObservers.set(observerId, allObservers)

			message.send({
				type: 'triggerCallback',
				target: 'service',
				body: {
					bridgeId,
					id: success,
					args: { observerId },
				},
			})
		// 延迟为了解决当前父组件 watch 触发的 nextTick 优先于组件的 created 生命周期导致异常，eg: emit 事件发送先于注册事件执行导致没有回调
		}, 300)
	}

	removeIntersectionObserver({ params: { observerId } }) {
		if (observerId) {
			const observers = this.intersectionObservers.get(observerId)
			if (observers) {
				// 断开所有观察器的连接
				observers.forEach(observer => observer.disconnect())
				this.intersectionObservers.delete(observerId)
			}
		}
	}

	addPerformanceObserver() {
		// TODO: 性能观察对象
	}
}

export default new Runtime()
