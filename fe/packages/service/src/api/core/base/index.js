import { invokeAPI } from '@/api/common'

/**
 * 文件系统
 * https://developers.weixin.qq.com/miniprogram/dev/framework/ability/file-system.html
 *
 * 环境变量
 * https://developers.weixin.qq.com/miniprogram/dev/api/base/wx.env.html
 */
export function env() {
	return {
		USER_DATA_PATH: 'difile://',
	}
}

/**
 * 判断小程序的API，回调，参数，组件等是否在当前版本可用。
 * https://developers.weixin.qq.com/miniprogram/dev/api/base/wx.canIUse.html
 */
export function canIUse(opts) {
	if (opts === 'getUpdateManager' || opts === 'getPerformance') {
		return true
	}
	return invokeAPI('canIUse', opts)
}
