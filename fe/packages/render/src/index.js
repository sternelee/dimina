import './core/namespace'
import { callback } from '@dimina/common'
import env from './core/env'
import message from './core/message'
import loader from './core/loader'
import runtime from './core/runtime'
/**
 * 渲染层消息通道
 */
class Render {
	constructor() {
		console.log('[Render] init')
		this.env = env
		this.message = message
		window.__message = message
		window.__callback = callback

		this.init()
	}

	init() {
		// 资源加载消息
		this.message.on('loadResource', (msg) => {
			const { bridgeId, appId, pagePath, root = '.' } = msg
			loader.loadResource({ bridgeId, appId, pagePath, root })
		})

		// 数据初始化消息
		this.message.on('firstRender', (msg) => {
			const { bridgeId, pageId, pagePath, initialProps, query } = msg

			loader.setInitialData(initialProps)
			runtime.firstRender({
				pagePath,
				pageId,
				bridgeId,
				query,
			})
		})

		this.message.on('u', (msg) => {
			queueMicrotask(() => {
				runtime.updateModule(msg)
			})
		})

		this.message.on('invokeAPI', (msg) => {
			runtime[msg.name](msg)
		})

		this.message.on('triggerCallback', (msg) => {
			const { success, data } = msg
			success && callback.invoke(success, data)
		})

		if (__DEV__) {
			// 可接收端容器或引擎日志
			this.message.on('print', (msg) => {
				const { type, detail } = msg
				switch (type) {
					case 'info':
						// eslint-disable-next-line no-console
						console.info(detail)
						break
					case 'debug':
						// eslint-disable-next-line no-console
						console.debug(detail)
						break
					case 'warn':
						console.warn(detail)
						break
					case 'error':
						console.error(detail)
						break
					default:
						console.log(detail)
						break
				}
			})
		}
	}
}

export default new Render()
