import { invokeAPI } from '@/api/common'
import { createNativeEvent } from '../../network/socket/shared'

const networkStatusChangeEvent = createNativeEvent(
	'onNetworkStatusChange',
	'offNetworkStatusChange',
)

/**
 * 获取网络类型
 *	https://developers.weixin.qq.com/miniprogram/dev/api/device/network/wx.getNetworkType.html
 * @param {*} opts
 */
export function getNetworkType(opts) {
	return invokeAPI('getNetworkType', opts)
}

/** 监听网络状态变化。 */
export function onNetworkStatusChange(listener) {
	return networkStatusChangeEvent.on(listener)
}

/** 移除网络状态变化监听。 */
export function offNetworkStatusChange(listener) {
	return networkStatusChangeEvent.off(listener)
}
