import { invokeAPI } from '@/api/common'

/**
 * 重启当前小程序
 * https://developers.weixin.qq.com/miniprogram/dev/api/navigate/wx.restartMiniProgram.html
 */
export function restartMiniProgram(opts) {
	invokeAPI('restartMiniProgram', opts)
}

/**
 * 打开另一个小程序
 * https://developers.weixin.qq.com/miniprogram/dev/api/navigate/wx.navigateToMiniProgram.html
 */
export function navigateToMiniProgram(opts) {
	invokeAPI('navigateToMiniProgram', opts)
}

/**
 * 返回到上一个小程序。只有在当前小程序是被其他小程序打开时可以调用成功
 * https://developers.weixin.qq.com/miniprogram/dev/api/navigate/wx.navigateBackMiniProgram.html
 */
export function navigateBackMiniProgram(opts) {
	invokeAPI('navigateBackMiniProgram', opts)
}

/**
 * 退出当前小程序。必须有点击行为才能调用成功
 * https://developers.weixin.qq.com/miniprogram/dev/api/navigate/wx.exitMiniProgram.html
 */
export function exitMiniProgram(opts) {
	invokeAPI('exitMiniProgram', opts)
}
