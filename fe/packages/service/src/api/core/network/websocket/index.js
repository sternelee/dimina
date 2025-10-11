import { invokeAPI } from '@/api/common'
import { callback, isFunction } from '@dimina/common'

/**
 * https://developers.weixin.qq.com/miniprogram/dev/api/network/websocket/SocketTask.html
 * SocketTask 类，用于管理 WebSocket 连接
 */
class SocketTask {
	constructor(socketId) {
		this.socketId = socketId
		this._readyState = 0 // CONNECTING
	}

	/**
	 * 通过 WebSocket 连接发送数据
	 * @param {Object} opts 
	 */
	send(opts = {}) {
		const { data, success, fail, complete, ...rest } = opts
		
		const params = {
			socketId: this.socketId,
			data,
			...rest
		}

		if (isFunction(success)) {
			params.success = callback.store(success)
		}
		if (isFunction(fail)) {
			params.fail = callback.store(fail)
		}
		if (isFunction(complete)) {
			params.complete = callback.store(complete)
		}

		return invokeAPI('sendSocketMessage', params)
	}

	/**
	 * 关闭 WebSocket 连接
	 * @param {Object} opts 
	 */
	close(opts = {}) {
		const { code = 1000, reason = '', success, fail, complete, ...rest } = opts
		
		const params = {
			socketId: this.socketId,
			code,
			reason,
			...rest
		}

		if (isFunction(success)) {
			params.success = callback.store(success)
		}
		if (isFunction(fail)) {
			params.fail = callback.store(fail)
		}
		if (isFunction(complete)) {
			params.complete = callback.store(complete)
		}

		return invokeAPI('closeSocket', params)
	}

	/**
	 * 监听 WebSocket 连接打开事件
	 * @param {Function} callback 回调函数
	 */
	onOpen(callbackFn) {
		if (isFunction(callbackFn)) {
			return invokeAPI('onSocketOpen', {
				socketId: this.socketId,
				callback: callback.store(callbackFn, true)
			})
		}
	}

	/**
	 * 取消监听 WebSocket 连接打开事件
	 * @param {Function} callback 回调函数
	 */
	offOpen(callbackFn) {
		return invokeAPI('offSocketOpen', {
			socketId: this.socketId,
			callback: callbackFn
		})
	}

	/**
	 * 监听 WebSocket 接受到服务器的消息事件
	 * @param {Function} callback 回调函数
	 */
	onMessage(callbackFn) {
		if (isFunction(callbackFn)) {
			return invokeAPI('onSocketMessage', {
				socketId: this.socketId,
				callback: callback.store(callbackFn, true)
			})
		}
	}

	/**
	 * 取消监听 WebSocket 接受到服务器的消息事件
	 * @param {Function} callback 回调函数
	 */
	offMessage(callbackFn) {
		return invokeAPI('offSocketMessage', {
			socketId: this.socketId,
			callback: callbackFn
		})
	}

	/**
	 * 监听 WebSocket 错误事件
	 * @param {Function} callback 回调函数
	 */
	onError(callbackFn) {
		if (isFunction(callbackFn)) {
			return invokeAPI('onSocketError', {
				socketId: this.socketId,
				callback: callback.store(callbackFn, true)
			})
		}
	}

	/**
	 * 取消监听 WebSocket 错误事件
	 * @param {Function} callback 回调函数
	 */
	offError(callbackFn) {
		return invokeAPI('offSocketError', {
			socketId: this.socketId,
			callback: callbackFn
		})
	}

	/**
	 * 监听 WebSocket 连接关闭事件
	 * @param {Function} callback 回调函数
	 */
	onClose(callbackFn) {
		if (isFunction(callbackFn)) {
			return invokeAPI('onSocketClose', {
				socketId: this.socketId,
				callback: callback.store(callbackFn, true)
			})
		}
	}

	/**
	 * 取消监听 WebSocket 连接关闭事件
	 * @param {Function} callback 回调函数
	 */
	offClose(callbackFn) {
		return invokeAPI('offSocketClose', {
			socketId: this.socketId,
			callback: callbackFn
		})
	}

	/**
	 * 获取 WebSocket 连接状态
	 * @returns {number} 连接状态
	 */
	get readyState() {
		return this._readyState
	}

	/**
	 * WebSocket 的连接状态常量
	 */
	static get CONNECTING() { return 0 }
	static get OPEN() { return 1 }
	static get CLOSING() { return 2 }
	static get CLOSED() { return 3 }
}

/**
 * 创建一个 WebSocket 连接
 * https://developers.weixin.qq.com/miniprogram/dev/api/network/websocket/wx.connectSocket.html
 * @param {Object} opts 配置对象
 * @param {string} opts.url 开发者服务器 wss 接口地址
 * @param {Object} [opts.header] HTTP Header，Header 中不能设置 Referer
 * @param {Array<string>} [opts.protocols] 子协议数组
 * @param {boolean} [opts.tcpNoDelay] 建立 TCP 连接的时候的 TCP_NODELAY 设置
 * @param {boolean} [opts.perMessageDeflate] 是否开启压缩扩展
 * @param {number} [opts.timeout] 超时时间，单位为毫秒
 * @param {boolean} [opts.forceCellularNetwork] 强制使用蜂窝网络发送请求
 * @param {Function} [opts.success] 接口调用成功的回调函数
 * @param {Function} [opts.fail] 接口调用失败的回调函数
 * @param {Function} [opts.complete] 接口调用结束的回调函数（调用成功、失败都会执行）
 * @returns {SocketTask} WebSocket 任务对象
 */
export function connectSocket(opts = {}) {
	const { 
		url, 
		header = {}, 
		protocols = [], 
		tcpNoDelay = false, 
		perMessageDeflate = false, 
		timeout, 
		forceCellularNetwork = false,
		success, 
		fail, 
		complete,
		...rest 
	} = opts

	// 验证必填参数
	if (!url) {
		const error = new Error('url is required')
		if (isFunction(fail)) {
			fail(error)
		}
		if (isFunction(complete)) {
			complete(error)
		}
		throw error
	}

	// 生成唯一的 socket ID
	const socketId = `socket_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`
	
	// 创建 SocketTask 实例
	const socketTask = new SocketTask(socketId)

	// 准备参数
	const params = {
		socketId,
		url,
		header,
		protocols,
		tcpNoDelay,
		perMessageDeflate,
		timeout,
		forceCellularNetwork,
		...rest
	}

	if (isFunction(success)) {
		params.success = callback.store((res) => {
			socketTask._readyState = SocketTask.OPEN
			success(res)
		})
	}
	if (isFunction(fail)) {
		params.fail = callback.store((error) => {
			socketTask._readyState = SocketTask.CLOSED
			fail(error)
		})
	}
	if (isFunction(complete)) {
		params.complete = callback.store(complete)
	}

	// 调用底层 API
	invokeAPI('connectSocket', params)

	return socketTask
}

/**
 * 通过 WebSocket 连接发送数据（全局方法，不推荐使用）
 * @deprecated 推荐使用 SocketTask 的方式管理 WebSocket 连接
 * @param {Object} opts 
 */
export function sendSocketMessage(opts) {
	return invokeAPI('sendSocketMessage', opts)
}

/**
 * 关闭 WebSocket 连接（全局方法，不推荐使用）
 * @deprecated 推荐使用 SocketTask 的方式管理 WebSocket 连接
 * @param {Object} opts 
 */
export function closeSocket(opts) {
	return invokeAPI('closeSocket', opts)
}

/**
 * 监听 WebSocket 连接打开事件（全局方法，不推荐使用）
 * @deprecated 推荐使用 SocketTask 的方式管理 WebSocket 连接
 * @param {Function} callback 
 */
export function onSocketOpen(callbackFn) {
	return invokeAPI('onSocketOpen', { callback: callback.store(callbackFn, true) })
}

/**
 * 监听 WebSocket 接受到服务器的消息事件（全局方法，不推荐使用）
 * @deprecated 推荐使用 SocketTask 的方式管理 WebSocket 连接
 * @param {Function} callback 
 */
export function onSocketMessage(callbackFn) {
	return invokeAPI('onSocketMessage', { callback: callback.store(callbackFn, true) })
}

/**
 * 监听 WebSocket 错误事件（全局方法，不推荐使用）
 * @deprecated 推荐使用 SocketTask 的方式管理 WebSocket 连接
 * @param {Function} callback 
 */
export function onSocketError(callbackFn) {
	return invokeAPI('onSocketError', { callback: callback.store(callbackFn, true) })
}

/**
 * 监听 WebSocket 连接关闭事件（全局方法，不推荐使用）
 * @deprecated 推荐使用 SocketTask 的方式管理 WebSocket 连接
 * @param {Function} callback 
 */
export function onSocketClose(callbackFn) {
	return invokeAPI('onSocketClose', { callback: callback.store(callbackFn, true) })
}
