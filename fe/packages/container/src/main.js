import '@/styles/app.scss'
import { Application } from '@/pages/application/application'
import { Device } from '@/pages/device/device'
import { AppList } from '@/pages/appList/appList'

window.onload = function () {
	const device = new Device()
	const application = new Application()
	const appListPage = new AppList()
	application.initRootView(appListPage)
	device.open(application)
}
