import { isFunction } from '@dimina/common'

let nextTickCallbackList = []
let nextTickTimer = null

function callNextTick() {
	const cbs = nextTickCallbackList
	nextTickCallbackList = []
	nextTickTimer = null

	for (let i = 0; i < cbs.length; i++) {
		cbs[i]()
	}
}

/**
 * 延迟一部分操作到下一个时间片再执行
 * https://developers.weixin.qq.com/miniprogram/dev/api/ui/custom-component/wx.nextTick.html
 */
export function nextTick(callback) {
	if (isFunction(callback)) {
		nextTickCallbackList.push((callback))
		if (!nextTickTimer) {
			nextTickTimer = setTimeout(callNextTick, 0)
		}
	}
}
