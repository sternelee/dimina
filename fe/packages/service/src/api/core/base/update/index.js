import { invokeAPI } from '@/api/common'
import message from '@/core/message'

/**
 * 获取全局唯一的版本更新管理器，用于管理小程序更新。关于小程序的更新机制，可以查看运行机制文档。
 * https://developers.weixin.qq.com/miniprogram/dev/api/base/update/wx.getUpdateManager.html
 */
export function getUpdateManager() {
	return UpdateManager.getInstance()
}

class UpdateManager {
	// 私有静态变量，用于存储单例实例
	static #instance = null

	// 私有构造函数，防止外部直接实例化
	constructor() {
		if (UpdateManager.#instance) {
			throw new Error(
				'Cannot instantiate more than one UpdateManager instance.',
			)
		}
		this.hasApplyUpdate = false

		this.updateFailFlag = null
		this.updateFailCbQueue = []

		this.updateReadyCbQueue = []
		this.updateReadyStatus = null
		this.updateReadyFlag = false

		this.updateStatus = null
		this.updateStatusCbQueue = []

		message.on('onUpdateStatusChange', (msg) => {
			const { event, strategy } = msg

			if (event === 'updatefail') {
				this.updateFailFlag = {}
				this.flashUpdateFailCb()
			}
			else if (event === 'updateready') {
				this.updateReadyFlag = true
				this.updateReadyStatus = { strategy }
				this.flushUpdateReadyCb()
			}
			else if (event === 'noupdate') {
				this.updateStatus = {
					hasUpdate: true,
				}
				this.flushUpdateStatusCb()
			}
			else if (event === 'updating') {
				this.updateStatus = {
					hasUpdate: false,
				}
				this.flushUpdateStatusCb()
			}
		})

		UpdateManager.#instance = this
	}

	flashUpdateFailCb() {
		this.updateFailCbQueue.forEach((cb) => {
			typeof cb === 'function' && cb()
		})
		this.updateFailCbQueue.length = 0
	}

	flushUpdateStatusCb() {
		this.updateStatusCbQueue.forEach((cb) => {
			typeof cb === 'function' && cb(this.updateStatus)
		})
		this.updateStatusCbQueue.length = 0
	}

	flushUpdateReadyCb() {
		this.updateReadyCbQueue.forEach((cb) => {
			typeof cb === 'function' && cb(this.updateReadyStatus)
		})
		this.updateReadyCbQueue.length = 0
	}

	// 静态方法，用于获取单例实例
	static getInstance() {
		if (!UpdateManager.#instance) {
			UpdateManager.#instance = new UpdateManager()
		}
		return UpdateManager.#instance
	}

	/**
	 * 强制小程序重启并使用新版本。在小程序新版本下载完成后（即收到 onUpdateReady 回调）调用。
	 * https://developers.weixin.qq.com/miniprogram/dev/api/base/update/UpdateManager.applyUpdate.html
	 */
	applyUpdate() {
		if (this.updateReadyFlag && this.hasApplyUpdate) {
			console.error('[applyUpdate]: applyUpdate has been called')
		}
		else if (!this.updateReadyFlag) {
			console.error('[applyUpdate]: update is not ready')
		}
		else {
			invokeAPI('applyUpdate')
		}
	}

	/**
	 * 监听向微信后台请求检查更新结果事件。微信在小程序每次启动（包括热启动）时自动检查更新，不需由开发者主动触发。
	 * https://developers.weixin.qq.com/miniprogram/dev/api/base/update/UpdateManager.onCheckForUpdate.html
	 */
	onCheckForUpdate(cb) {
		this.updateStatus ? typeof cb === 'function' && cb(this.updateStatus) : this.updateStatusCbQueue.push(cb)
	}

	/**
	 * 监听小程序更新失败事件。小程序有新版本，客户端主动触发下载（无需开发者触发），下载失败（可能是网络原因等）后回调
	 * https://developers.weixin.qq.com/miniprogram/dev/api/base/update/UpdateManager.onUpdateFailed.html
	 */
	onUpdateFailed(cb) {
		this.updateFailFlag ? typeof cb === 'function' && cb(this.updateFailFlag) : this.updateFailCbQueue.push(cb)
	}

	/**
	 * 监听小程序有版本更新事件。客户端主动触发下载（无需开发者触发），下载成功后回调
	 *	https://developers.weixin.qq.com/miniprogram/dev/api/base/update/UpdateManager.onUpdateReady.html
	 */
	onUpdateReady(cb) {
		this.updateReadyFlag ? typeof cb === 'function' && cb(this.updateReadyStatus) : this.updateReadyCbQueue.push(cb)
	}
}
