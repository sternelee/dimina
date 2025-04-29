import { isFunction } from '@dimina/common'

const lifecycleMethods = ['onLaunch', 'onShow', 'onHide']
export class App {
	constructor(appModule, options) {
		this.appModule = appModule
		this.options = options
		this.init()
	}

	init() {
		this.initLifecycle()
		this.initCustomMethods()
		this.invokeSomeLifecycle()
	}

	initLifecycle() {
		// https://developers.weixin.qq.com/miniprogram/dev/reference/api/App.html
		lifecycleMethods.forEach((method) => {
			const lifecycleMethod = this.appModule.moduleInfo[method]
			if (!isFunction(lifecycleMethod)) {
				return
			}
			this[method] = lifecycleMethod.bind(this)
		})
	}

	// 开发者自定义函数
	initCustomMethods() {
		const moduleInfo = this.appModule.moduleInfo
		for (const attr in moduleInfo) {
			if (!lifecycleMethods.includes(attr) && isFunction(moduleInfo[attr])) {
				this[attr] = moduleInfo[attr].bind(this)
			}
		}
	}

	invokeSomeLifecycle() {
		this.onLaunch?.(this.options)
		this.onShow?.(this.options)
	}

	appShow() {
		this.onShow?.(this.options)
	}

	appHide() {
		this.onHide?.()
	}
}
