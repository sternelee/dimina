import { Application } from '@/pages/application/application'
import { AppList } from '@/pages/appList/appList'
import { Device } from '@/pages/device/device'
import '@/styles/app.scss'

window.onload = function () {
	const device = new Device()
	const application = new Application()
	const appListPage = new AppList()
	application.initRootView(appListPage)
	device.open(application)
}
