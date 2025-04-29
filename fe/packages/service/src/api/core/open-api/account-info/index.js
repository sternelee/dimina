import { invokeAPI } from '@/api/common'

/**
 * 获取当前账号信息
 * https://developers.weixin.qq.com/miniprogram/dev/api/open-api/account-info/wx.getAccountInfoSync.html
 */
export function getAccountInfoSync() {
	return invokeAPI('getAccountInfoSync')
}
