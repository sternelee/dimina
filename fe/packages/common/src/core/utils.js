import { getProperty, setProperty } from 'dot-prop'

export function isFunction(value) {
	return typeof value === 'function'
}

export function isNumber(value) {
	return typeof value === 'number' && Number.isFinite(value) && !Number.isNaN(value)
}

export function isString(value) {
	return typeof value === 'string'
}

export function isNil(value) {
	return value === null || value === undefined
}

export function get(data, path) {
	return getProperty(data, path)
}

export function set(data, path, value) {
	setProperty(data, path, value)
}

export function uuid() {
	return Math.random().toString(36).slice(2, 7)
}

export function sleep(time) {
	return new Promise((resolve) => {
		setTimeout(() => {
			resolve()
		}, time)
	})
}

export function toCamelCase(attr) {
	return attr.toLowerCase().replace(/-(.)/g, (_, group) => {
		return group.toUpperCase()
	})
}

export function camelCaseToUnderscore(str) {
	return str.replace(/([a-z])([A-Z])/g, '$1-$2').toLowerCase()
}

/**
 * 通过 vnode 获取 data 属性
 * @param {*} attrs
 * @param {*} handler
 */
export function getDataAttributes(attrs, handler) {
	if (!attrs) {
		return
	}
	const result = {}
	for (const attr in attrs) {
		if (!attr.startsWith('data-')) {
			continue
		}
		const theAfter = attr.replace(/^data-/, '')
		const transAttr = toCamelCase(theAfter)
		result[transAttr] = handler(attrs[attr])
	}

	return result
}

/**
 * 判断内容是否是纯数字
 * @param {string} str
 */
export function isPureNumber(str) {
	return /^\d+$/.test(str)
};

export const isAndroid = typeof navigator !== 'undefined' && /Android/i.test(navigator.userAgent)

export const isIOS = typeof navigator !== 'undefined' && /iPad|iPhone|iPod/.test(navigator.userAgent)

export const isHarmonyOS = typeof navigator !== 'undefined' && /OpenHarmony|harmony/.test(navigator.userAgent)

export const isDesktop = typeof navigator !== 'undefined' && /Mac|Windows|Linux/.test(navigator.userAgent)

export const isWebWorker = (() => {
	// eslint-disable-next-line no-undef
	if (typeof WorkerGlobalScope !== 'undefined' && globalThis instanceof WorkerGlobalScope) {
		// 代码在Web Worker内运行
		return true
	}
	else {
		return false
	}
})()

function resolvePath(basePath, relativePath) {
	// 如果相对路径以'/'开头，则将其视为根路径下的路径
	if (relativePath.startsWith('/')) {
		// 移除开头的'/'
		return relativePath.slice(1)
	}

	const currParts = basePath.split('/')
	const relativeParts = relativePath.split('/')

	for (const element of relativeParts) {
		const part = element
		if (part === '..') {
			// 向上级目录移动
			if (currParts.length > 0) {
				currParts.pop() // 移除最后一个部分（通常是当前目录）
			}
		}
		else if (part !== '.' && part !== '') {
			// 将相对路径部分添加到解析后的路径中
			currParts.push(part)
		}
	}
	return currParts.join('/')
}

export function parsePath(currPath, url) {
	// 处理路径问题
	const basePath = currPath.split('/').slice(0, -1).join('/')
	const parts = url.split('?')
	const pagePath = parts[0]
	const paramStr = parts[1]
	let newUrl = resolvePath(basePath, pagePath)
	if (paramStr) {
		newUrl += `?${paramStr}`
	}
	return newUrl
}

// TODO: 合并 compiler 下的 transformRpx
const rpxRegex = /([+-]?\d+(?:\.\d+)?)rpx/g
export function transformRpx(styleText) {
	if (!isString(styleText)) {
		return styleText
	}
	return styleText.replace(rpxRegex, (match, pixel) => {
		return `${Number(pixel)}rem`
	})
}

function suffixPixel(value) {
	return isNumber(value) ? `${value}px` : value
}

/**
 * 添加 Deg 后缀
 */
function suffixDegree(value) {
	return `${value}deg`
}

/**
 * 转化 animate 中 transform 的支持类型为 cssText 中的值
 */
const transformHandler = {
	matrix(args) {
		return `matrix(${args.join(', ')})`
	},
	matrix3d(args) {
		return `matrix3d(${args.join(', ')})`
	},
	rotate(args) {
		const [angle] = args.map(suffixDegree)
		return `rotate(${angle})`
	},
	rotate3d(args) {
		args[3] = suffixDegree(args[3])
		return `rotate3d(${args.join(', ')})`
	},
	rotateX(args) {
		const [angle] = args.map(suffixDegree)
		return `rotateX(${angle})`
	},
	rotateY(args) {
		const [angle] = args.map(suffixDegree)
		return `rotateY(${angle})`
	},
	rotateZ(args) {
		const [angle] = args.map(suffixDegree)
		return `rotateZ(${angle})`
	},
	scale(args) {
		return `scale(${args.join(', ')})`
	},
	scale3d(args) {
		return `scale3d(${args.join(', ')})`
	},
	scaleX(args) {
		return `scaleX(${args[0]})`
	},
	scaleY(args) {
		return `scaleY(${args[0]})`
	},
	scaleZ(args) {
		return `scaleZ(${args[0]})`
	},
	skew(args) {
		const _args = args.map(suffixDegree)
		return `skew(${_args.join(', ')})`
	},
	skewX(args) {
		const [angle] = args.map(suffixDegree)
		return `skewX(${angle})`
	},
	skewY(args) {
		const [angle] = args.map(suffixDegree)
		return `skewY(${angle})`
	},
	translate(args) {
		const _args = args.map(suffixPixel)
		return `translate(${_args.join(', ')})`
	},
	translate3d(args) {
		const _args = args.map(suffixPixel)
		return `translate3d(${_args.join(', ')})`
	},
	translateX(args) {
		const [value] = args.map(suffixPixel)
		return `translateX(${value})`
	},
	translateY(args) {
		const [value] = args.map(suffixPixel)
		return `translateY(${value})`
	},
	translateZ(args) {
		const [value] = args.map(suffixPixel)
		return `translateZ(${value})`
	},
}

export function animationToStyle(action) {
	const { animates, option } = action

	const transformOrigin = option.transformOrigin
	const transition = option.transition

	if (transformOrigin === undefined || transition === undefined) {
		return {
			transformOrigin: '',
			transform: '',
			transition: '',
		}
	}

	// 处理 transform
	const transform = animates
		.filter(animate => animate.type !== 'style')
		.map((animate) => {
			const { type, args } = animate
			if (isFunction(transformHandler[type])) {
				return transformHandler[type](args)
			}
			console.warn(`[Common] SDK inner warning (Transform Handler not found animation type: ${type})`)
			return ''
		})
		.join(' ')

	// 处理样式属性
	const styles = {}
	animates
		.filter(animate => animate.type === 'style')
		.forEach((animate) => {
			const [prop, value] = animate.args
			styles[prop] = value
		})

	return {
		keyframes: [
			{
				transform,
				transformOrigin,
				...styles,
			},
		],
		options: {
			duration: transition.duration,
			easing: transition.timingFunction,
			delay: transition.delay,
			fill: 'forwards', // 保持动画最后一帧的状态
		},
	}
}

/**
 * 高效的深拷贝实现
 * @param {*} value - 要拷贝的值
 * @returns {*} 拷贝后的值
 */
export function cloneDeep(value) {
	// 处理原始类型和函数
	if (value === null || typeof value !== 'object') {
		return value
	}

	// 使用 WeakMap 处理循环引用
	const seen = new WeakMap()

	function clone(item) {
		// 处理原始类型和函数
		if (item === null || typeof item !== 'object') {
			return item
		}

		// 处理日期对象
		if (item instanceof Date) {
			return new Date(item)
		}

		// 处理正则表达式
		if (item instanceof RegExp) {
			return new RegExp(item.source, item.flags)
		}

		// 处理数组
		if (Array.isArray(item)) {
			if (seen.has(item)) {
				return seen.get(item)
			}
			const arr = []
			seen.set(item, arr)
			arr.push(...item.map(clone))
			return arr
		}

		// 处理普通对象
		if (seen.has(item)) {
			return seen.get(item)
		}

		const obj = Object.create(Object.getPrototypeOf(item))
		seen.set(item, obj)

		return Object.assign(obj, ...Object.keys(item).map(key => ({
			[key]: clone(item[key]),
		})))
	}

	return clone(value)
}
