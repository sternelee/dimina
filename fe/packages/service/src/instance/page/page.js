import { cloneDeep, isFunction, set } from '@dimina/common'
import message from '../../core/message'
import { addComputedData, filterData } from '../../core/utils'

// https://developers.weixin.qq.com/miniprogram/dev/reference/api/Page.html
// const lifecycleMethods = ['onLoad', 'onShow', 'onReady', 'onHide', 'onUnload',
//     'onPullDownRefresh', 'onReachBottom', 'onShareAppMessage', 'onPageScroll',
//     'onResize', 'onTabItemTap'
// ];

export class Page {
	constructor(module, opts) {
		this.initd = false
		this.opts = opts
		this.is = opts.path
		this.bridgeId = opts.bridgeId
		this.data = cloneDeep(module.noReferenceData)
		this.__type__ = module.type
		this.__id__ = opts.moduleId
		this.__info__ = module.moduleInfo

		this.#init()
	}

	#init() {
		this.#initMembers()
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

	// 开发者自定义函数
	#initMembers() {
		for (const attr in this.__info__) {
			const member = this.__info__[attr]
			if (isFunction(member)) {
				this[attr] = member.bind(this)
			}
			else {
				this[attr] = member
			}
		}
	}

	async #invokeInitLifecycle() {
		// 页面创建时执行
		await this.onLoad?.(this.opts.query || {})
		this.initd = true
	}

	/**
	 * 页面显示/切入前台时触发。该时机不能保证页面渲染完成，如有页面/组件元素相关操作建议在 onReady 中处理
	 */
	pageShow() {
		this.onShow?.()
	}

	pageHide() {
		this.onHide?.()
	}

	pageReady() {
		this.onReady?.()
	}

	pageUnload() {
		this.onUnload?.()
		this.initd = false
	}

	pageScrollTop(opts) {
		const { scrollTop } = opts
		this.onPageScroll?.({ scrollTop })
	}
}
