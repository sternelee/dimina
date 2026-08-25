import { createBluetoothEvent } from '../bluetooth/shared'
import { invokeAPI } from '@/api/common'

const userCaptureScreenEvent = createBluetoothEvent(
	'onUserCaptureScreen',
	'offUserCaptureScreen',
)
let userCaptureScreenListener

/**
 * 监听用户主动截屏事件。
 * https://developers.weixin.qq.com/miniprogram/dev/api/device/screen/wx.onUserCaptureScreen.html
 */
export function onUserCaptureScreen(listener) {
	if (typeof listener !== 'function') {
		return
	}
	if (userCaptureScreenListener && userCaptureScreenListener !== listener) {
		userCaptureScreenEvent.off(userCaptureScreenListener)
	}
	userCaptureScreenListener = listener
	return userCaptureScreenEvent.on(listener)
}

/**
 * 移除用户主动截屏事件的监听函数。
 * https://developers.weixin.qq.com/miniprogram/dev/api/device/screen/wx.offUserCaptureScreen.html
 */
export function offUserCaptureScreen(listener) {
	if (typeof listener === 'function' && listener !== userCaptureScreenListener) {
		return
	}
	userCaptureScreenListener = undefined
	return userCaptureScreenEvent.off(listener)
}

/** 设置是否保持屏幕常亮。 */
export function setKeepScreenOn(opts) {
	return invokeAPI('setKeepScreenOn', opts)
}
