import { AppManager } from '@/core/appManager'
import { Application } from '@/pages/application/application'
import { AppList } from '@/pages/appList/appList'
import { Device } from '@/pages/device/device'
import { HashRouter } from '@/utils/hashRouter'
import '@/styles/app.scss'

window.onload = function () {
	const device = new Device()
	const application = new Application()
	const appListPage = new AppList()
	application.initRootView(appListPage)
	device.open(application)

	// 刷新后从 hash 恢复小程序及完整页面栈
	const parsed = HashRouter.parse(window.location.hash)
	if (parsed) {
		const rootPage = parsed.stack[0]
		// path 格式为 pagePath?query，queryPath 会统一处理
		const rootPath = rootPage.query && Object.keys(rootPage.query).length > 0
			? `${rootPage.pagePath}?${Object.entries(rootPage.query).map(([k, v]) => `${k}=${encodeURIComponent(v)}`).join('&')}`
			: rootPage.pagePath
		AppManager.openApp({
			appId: parsed.appId,
			path: rootPath,
			scene: 1001,
			destroy: true,
			restoreStack: parsed.stack, // 完整栈，用于静默恢复二级页面
		}, application)
	}
}
