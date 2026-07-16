import { animationToStyle, getDataAttributes, toCamelCase, transformRpx } from '@dimina/common'
import { triggerEvent, useInfo } from '@/common/events'
import { deepToRaw, install, replaceExternalClassTokens } from '@/common/utils'
import components from './src/index'

export * from './src/index'

const EXTERNAL_CLASS_SCOPE_ATTRIBUTE = 'data-dd-external-class-scope'

function transformAnimation(el, propertyValue) {
	if (!propertyValue?.actions?.length)
		return

	let currentIndex = 0
	const actions = propertyValue.actions

	function executeAnimation() {
		if (currentIndex >= actions.length)
			return

		const currentAction = actions[currentIndex]
		const style = animationToStyle(currentAction)

		// 创建动画
		const animation = el.animate(
			style.keyframes,
			style.options,
		)

		// 设置动画完成回调，执行下一个动画
		animation.onfinish = () => {
			currentIndex++
			executeAnimation()
		}
	}
	// 开始执行动画序列
	executeAnimation()
}

function transformCss(el, val, append) {
	const convertedStyle = transformRpx(val)
	if (append) {
		// 防止覆盖组件自身样式
		el.style.cssText += convertedStyle
	}
	else {
		el.style.cssText = convertedStyle
	}
}

function parseDataset(el, vnode) {
	el._ds = getDataAttributes(vnode.ctx.attrs, deepToRaw)
}

function parseExternalClass(el, instance, vnode) {
	const ctx = vnode.ctx
	if (instance.props && Array.isArray(ctx.provides.externalClasses)) {
		for(const externalClass of ctx.provides.externalClasses) {
			const clsName = instance.props[toCamelCase(externalClass)]
			if (clsName) {
				el.className = replaceExternalClassTokens(el.className, externalClass, clsName)
				if (!el.hasAttribute(instance.sId)) {
					el.setAttribute(instance.sId, '')
				}
				const scopeTokens = new Set(
					(el.getAttribute(EXTERNAL_CLASS_SCOPE_ATTRIBUTE) || '').split(/\s+/).filter(Boolean),
				)
				scopeTokens.add(instance.sId)
				el.setAttribute(EXTERNAL_CLASS_SCOPE_ATTRIBUTE, [...scopeTokens].join(' '))
			}
		}
	}
}

function collectEventBindings(props = {}) {
	const eventBindings = {}
	for (const [attrName, handler] of Object.entries(props || {})) {
		const match = attrName.match(/^(capture-)?(bind|catch)(?::)?(.+)$/)
		if (!match || handler === undefined || handler === null || handler === '') {
			continue
		}

		const [, capture, listenerType, eventType] = match
		const bindingType = capture
			? (listenerType === 'catch' ? 'captureCatch' : 'captureBind')
			: listenerType
		eventBindings[eventType] = eventBindings[eventType] || {}
		eventBindings[eventType][bindingType] = handler
	}
	return eventBindings
}

function getEventBindingRecord(el, binding, vnode) {
	const target = vnode.component?.proxy
	return el._ddEventBindings?.find(record => (
		record.owner === binding.instance
		&& record.target === target
		&& record.nodeType === binding.value
	))
}

function mountEventBindingRecord(el, binding, vnode) {
	const record = {
		owner: binding.instance,
		target: vnode.component?.proxy,
		nodeType: binding.value,
		eventAttr: collectEventBindings(vnode.props),
	}
	el._ddEventBindings = el._ddEventBindings || []
	el._ddEventBindings.push(record)
}

function updateEventBindingRecord(el, binding, vnode) {
	const record = getEventBindingRecord(el, binding, vnode)
	if (record) {
		record.eventAttr = collectEventBindings(vnode.props)
	}
}

function removeEventBindingRecord(el, binding, vnode) {
	const record = getEventBindingRecord(el, binding, vnode)
	if (!record) {
		return
	}
	const index = el._ddEventBindings.indexOf(record)
	if (index >= 0) {
		el._ddEventBindings.splice(index, 1)
	}
}

function Components(app) {
	app.directive('c-style', {
		mounted(el, binding) {
			transformCss(el, binding.value, true)
		},
		updated(el, binding) {
			transformCss(el, binding.value, false)
		},
	})

	app.directive('c-animation', {
		mounted(el, binding) {
			transformAnimation(el, binding.value)
		},
		updated(el, binding) {
			transformAnimation(el, binding.value)
		},
	})

	app.directive('c-data', {
		mounted(el, _binding, vnode) {
			parseDataset(el, vnode)
		},
		updated(el, _binding, vnode) {
			parseDataset(el, vnode)
		},
	})

	app.directive('c-class', {
		mounted(el, binding, vnode) {
			parseExternalClass(el, binding.instance, vnode)
		},
		updated(el, binding, vnode) {
			parseExternalClass(el, binding.instance, vnode)
		},
	})

	app.directive('c-prop-bindings', {
		mounted(el, binding) {
			// 将属性绑定信息存储在 DOM 元素上，供 render 层使用
			// 使用动态绑定，Vue 会自动将 HTML 实体解码后的 JSON 解析为对象
			el._propBindings = binding.value || {}
		},
	})

	app.directive('c-event-node', {
		mounted(el, binding, vnode) {
			mountEventBindingRecord(el, binding, vnode)
		},
		updated(el, binding, vnode) {
			updateEventBindingRecord(el, binding, vnode)
		},
		beforeUnmount(el, binding, vnode) {
			removeEventBindingRecord(el, binding, vnode)
		},
	})

	return components.forEach((component) => {
		component.mixins = [{
			inheritAttrs: false,
		}]
		install(app, component)
	})
}

const tagWhiteList = components.map(obj => obj.__tagName)

export { Components, deepToRaw, tagWhiteList, triggerEvent, useInfo }
