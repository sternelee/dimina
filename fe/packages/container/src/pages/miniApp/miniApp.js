import './miniApp.scss'
import tpl from './miniApp.html?raw'
import { mergePageConfig, queryPath, readFile, sleep, uuid } from '@/utils/util'
import { AppManager } from '@/core/appManager'
import { Bridge } from '@/core/bridge'
import { JSCore } from '@/core/jscore'

export class MiniApp {
	constructor(opts) {
		this.appInfo = opts
		this.id = `mini_app_${uuid()}`
		this.parent = null
		this.appId = opts.appId
		this.appConfig = null
		this.bridgeList = []
		this.jscore = new JSCore(this)
		this.webviewsContainer = null
		this.webviewAnimaEnd = true
		this.el = document.createElement('div')
		this.el.classList.add('dimina-native-view')
		this.toastInfo = {
			dom: null,
			timer: null,
		}
		this.color = null
	}

	viewDidLoad() {
		this.initPageFrame()
		this.webviewsContainer = this.el.querySelector('.dimina-mini-app__webviews')
		this.showLaunchScreen()
		this.bindMoreEvent()
		this.bindCloseEvent()
		this.initApp()
	}

	async initApp() {
		// 1. 等待逻辑线程初始化
		await this.jscore.init()

		// 2. 模拟拉取小程序资源
		await sleep(260)

		// 3. 读取配置文件
		const root = 'main'
		const configPath = `${this.appInfo.appId}/${root}/app-config.json`
		const configContent = await readFile(configPath)

		if (!configContent) {
			return
		}

		this.appConfig = JSON.parse(configContent)

		const entryPagePath = this.appInfo.pagePath || this.appConfig.app.entryPagePath

		// 4. 读取页面配置
		const pageConfig = this.appConfig.modules[entryPagePath]
		const mergeConfig = mergePageConfig(this.appConfig.app, pageConfig)

		// 5. 设置状态栏的颜色模式
		this.updateTargetPageColorStyle(mergeConfig)

		// 6. 创建通信 bridge
		const entryPageBridge = await this.createBridge({
			pagePath: entryPagePath,
			query: this.appInfo.query,
			scene: this.appInfo.scene,
			jscore: this.jscore,
			isRoot: true,
			root,
			appId: this.appInfo.appId,
			pages: this.appConfig.app.pages,
			configInfo: mergeConfig,
		})

		this.bridgeList.push(entryPageBridge)
		entryPageBridge.start()

		// 6.隐藏 loading
		this.hideLaunchScreen()
	}

	// 创建一个bridge对象
	async createBridge(opts) {
		const { jscore, configInfo, isRoot, appId, pagePath, query, scene, pages, root } = opts
		const bridge = new Bridge({
			jscore,
			configInfo,
			isRoot,
			appId,
			pagePath,
			query,
			scene,
			pages,
			root,
		})

		bridge.parent = this
		await bridge.init()
		return bridge
	}

	onPresentIn() {
		const currentBridge = this.bridgeList[this.bridgeList.length - 1]
		// 首次异步创建时， bridge 不存在，会在[Service]自行调用 invokeInitLifecycle
		currentBridge?.appShow()
		currentBridge?.pageShow()
	}

	onPresentOut() {
		const currentBridge = this.bridgeList[this.bridgeList.length - 1]

		currentBridge?.appHide()
		currentBridge?.pageHide()
	}

	initPageFrame() {
		this.el.innerHTML = tpl
	}

	// 设置指定页面状态栏的颜色模式
	updateTargetPageColorStyle(mergeConfig) {
		const { navigationBarTextStyle } = mergeConfig
		this.updateActionColorStyle(navigationBarTextStyle)
	}

	showLaunchScreen() {
		const launchScreen = this.el.querySelector('.dimina-mini-app__launch-screen')
		const name = this.el.querySelector('.dimina-mini-app__name')
		const logo = this.el.querySelector('.dimina-mini-app__logo-img-url')

		this.updateActionColorStyle('black')
		name.innerHTML = this.appInfo.name
		logo.src = this.appInfo.logo
		launchScreen.style.display = 'block'
	}

	hideLaunchScreen() {
		const startPage = this.el.querySelector('.dimina-mini-app__launch-screen')
		startPage.style.display = 'none'
	}

	updateActionColorStyle(color) {
		this.color = color
		const action = this.el.querySelector('.dimina-mini-app-navigation__actions')

		if (color === 'white') {
			action.classList.remove('dimina-mini-app-navigation__actions--black')
			action.classList.add('dimina-mini-app-navigation__actions--white')
		}
		else if (color === 'black') {
			action.classList.remove('dimina-mini-app-navigation__actions--white')
			action.classList.add('dimina-mini-app-navigation__actions--black')
		}

		this.parent.updateStatusBarColor(color)
	}

	restoreColorStyle() {
		this.updateActionColorStyle(this.color)
	}

	createCallbackFunction(funcId) {
		if (funcId) {
			return (args) => {
				this.jscore.postMessage({
					type: 'triggerCallback',
					body: {
						id: funcId,
						args,
					},
				})
			}
		}
	}

	async navigateTo(opts) {
		// 防抖处理
		if (!this.webviewAnimaEnd) {
			return
		}
		this.webviewAnimaEnd = false

		const { url, success } = opts
		const { query, pagePath } = queryPath(url)
		const onSuccess = this.createCallbackFunction(success)

		const pageConfig = this.appConfig.modules[pagePath]
		const mergeConfig = mergePageConfig(this.appConfig.app, pageConfig)
		// 更新状态栏颜色模式
		this.updateTargetPageColorStyle(mergeConfig)

		// 创建新的入口页面的 bridge
		const bridge = await this.createBridge({
			pagePath,
			query,
			scene: this.appInfo.scene,
			jscore: this.jscore,
			isRoot: false,
			root: pageConfig?.root || 'main',
			appId: this.appInfo.appId,
			pages: this.appConfig.app.pages,
			configInfo: mergeConfig,
		})

		// 获取前一个bridge
		const preBridge = this.bridgeList[this.bridgeList.length - 1]
		const preWebview = preBridge.webview

		this.bridgeList.push(bridge)

		// 触发新页面的初始化逻辑
		bridge.start()

		// 上一个页面推出
		preWebview.el.classList.remove('dimina-native-view--instage')
		preWebview.el.classList.add('dimina-native-view--slide-out')
		preWebview.el.classList.add('dimina-native-view--linear-anima')
		preBridge?.pageHide()

		// 新页面推入
		bridge.webview.el.style.zIndex = this.bridgeList.length + 1
		bridge.webview.el.classList.add('dimina-native-view--enter-anima')
		bridge.webview.el.classList.add('dimina-native-view--instage')
		await sleep(540)

		// 页面进入后移出动画相关class
		this.webviewAnimaEnd = true
		preWebview.el.classList.remove('dimina-native-view--linear-anima')
		bridge.webview.el.classList.remove('dimina-native-view--before-enter')
		bridge.webview.el.classList.remove('dimina-native-view--enter-anima')
		bridge.webview.el.classList.remove('dimina-native-view--instage')

		onSuccess?.()
	}

	redirectTo(opts) {
		// 防抖处理
		if (!this.webviewAnimaEnd) {
			return
		}
		this.webviewAnimaEnd = false

		const { url, success } = opts
		const { query, pagePath } = queryPath(url)
		const onSuccess = this.createCallbackFunction(success)

		// 获取当前 bridge
		const curBridge = this.bridgeList[this.bridgeList.length - 1]
		const pageConfig = this.appConfig.modules[pagePath]
		const mergeConfig = mergePageConfig(this.appConfig.app, pageConfig)

		this.updateTargetPageColorStyle(mergeConfig)
		// 更新 bridge
		curBridge.destroy()
		curBridge.opts = {
			...curBridge.opts,
			pagePath,
			query,
			configInfo: mergeConfig,
		}
		curBridge.resetStatus()
		curBridge.start()

		this.webviewAnimaEnd = true
		onSuccess?.()
	}

	async navigateBack() {
		if (this.bridgeList.length < 2) {
			return
		}

		if (!this.webviewAnimaEnd) {
			return
		}

		this.webviewAnimaEnd = false

		const currentBridge = this.bridgeList.pop()
		const preBridge = this.bridgeList[this.bridgeList.length - 1]

		const pageConfig = this.appConfig.modules[preBridge.opts.pagePath]
		const mergeConfig = mergePageConfig(this.appConfig.app, pageConfig)

		// 更新状态栏颜色模式
		this.updateTargetPageColorStyle(mergeConfig)

		// 当前页面推出
		currentBridge.webview.el.classList.add('dimina-native-view--before-enter')
		currentBridge.webview.el.classList.add('dimina-native-view--enter-anima')

		// 触发当前页面的生命周期函数
		currentBridge?.destroy()

		// 上一个页面推入
		preBridge.webview.el.classList.remove('dimina-native-view--slide-out')
		preBridge.webview.el.classList.add('dimina-native-view--instage')
		preBridge.webview.el.classList.add('dimina-native-view--enter-anima')

		// 触发上一个页面的生命周期函数
		preBridge?.pageShow()
		await sleep(540)
		this.webviewAnimaEnd = true

		// 页面进入后移出动画相关class
		preBridge.webview.el.classList.remove('dimina-native-view--enter-anima')
		preBridge.webview.el.classList.remove('dimina-native-view--instage')
		currentBridge.webview.el.parentNode.removeChild(currentBridge.webview.el)
	}

	navigateToMiniProgram(opts) {
		const { appId, path } = opts
		AppManager.openApp(
			{
				appId,
				path,
				scene: 1037, // 打开小程序
			},
			this.parent,
		)
	}

	bindMoreEvent() {
		const moreBtn = this.el.querySelector('.dimina-mini-app-navigation__actions-variable')
		const dialog = this.el.querySelector('.dimina-mini-app_dialog-content')
		const overlay = this.el.querySelector('.dimina-mini-app_dialog-bg')
		const info = this.el.querySelector('.dimina-mini-app_dialog-info')
		info.innerHTML = `app id: ${this.appId}`

		overlay.addEventListener('transitionend', () => {
			if (overlay.style.opacity === '0') {
				overlay.style.display = 'none'
			}
		})

		moreBtn.onclick = () => {
			overlay.style.display = 'block'
			overlay.style.opacity = 1
			dialog.classList.add('show')
		}

		overlay.onclick = () => {
			overlay.style.opacity = 0
			dialog.classList.remove('show')
		}
	}

	bindCloseEvent() {
		const closeBtn = this.el.querySelector('.dimina-mini-app-navigation__actions-close')

		closeBtn.onclick = () => {
			AppManager.closeApp(this)
		}
	}

	destroy() {
		AppManager.popView()
		this.jscore.destroy()
	}

	/**
	 * 获取网络类型
	 * https://developers.weixin.qq.com/miniprogram/dev/api/device/network/wx.getNetworkType.html
	 */
	getNetworkType(opts) {
		const { success } = opts
		const onSuccess = this.createCallbackFunction(success)
		onSuccess?.({
			networkType: 'wifi',
		})
	}

	/**
	 * 发起 HTTPS 网络请求
	 * https://developers.weixin.qq.com/miniprogram/dev/api/network/request/wx.request.html
	 * @param {*} param0
	 */
	request({
		url,
		data,
		header = {}, // 默认为空对象
		timeout = 0, // 默认为0，表示没有超时
		method = 'GET', // 默认为GET方法
		dataType = 'json', // 默认为json类型
		responseType = 'text', // 响应的数据类型，默认为 text
		success,
		fail,
		complete,
	}) {
		// 创建一个AbortController实例
		// const controller = new AbortController();
		// const { signal } = controller;

		// 创建fetch请求的init对象
		const init = {
			method: 'POST',
			headers: {
				'Content-Type': 'application/json',
			},
			body: JSON.stringify({
				url,
				data,
				header,
				timeout,
				method,
				dataType,
				responseType,
			}),
		}

		const onSuccess = this.createCallbackFunction(success)
		const onFail = this.createCallbackFunction(fail)
		const onComplete = this.createCallbackFunction(complete)

		fetch('http://localhost:7788/proxy', init)
			.then((response) => {
				if (!response.ok) {
					const error = new Error(response.statusText)
					error.code = response.status
					throw error
				}
				switch (dataType) {
					case 'json':
						return response.json()
					case 'arraybuffer':
						return response.arrayBuffer()
					default:
						return response.text()
				}
			})
			.then((data) => {
				onSuccess?.({
					statusCode: 200,
					data,
					header: {},
				})
			})
			.catch((error) => {
				onFail?.({ errMsg: error.message, errno: error.code })
			})
			.finally(() => {
				onComplete?.()
			})

		// return { abort: controller.abort };
	}

	getSystemInfoSync() {
		const bar = this.parent.parent.root.querySelector('.iphone__status-bar').getBoundingClientRect()
		const wb = this.parent.el.querySelector('.dimina-native-webview__root').getBoundingClientRect()

		return {
			statusBarHeight: bar.height,
			brand: 'devtools',
			mode: 'default',
			model: 'web',
			platform: 'devtools',
			system: 'web',
			deviceOrientation: 'portrait',
			SDKVersion: '1.0.0',
			language: 'zh_CN',
			wifiEnabled: true,
			safeArea: {
				width: wb.width,
				height: wb.height,
				top: wb.top,
				bottom: wb.bottom,
				left: wb.left,
				right: wb.right,
			},
		}
	}

	getSystemInfo() {
		return this.getSystemInfoSync()
	}

	getMenuButtonBoundingClientRect() {
		return this.el.querySelector('.dimina-mini-app-navigation__actions').getBoundingClientRect()
	}

	showToast(opts) {
		const { title = '', duration = 1500, icon = 'success', success, complete } = opts

		if (!title) {
			return
		}

		this.hideToast({})

		const onSuccess = this.createCallbackFunction(success)
		const onComplete = this.createCallbackFunction(complete)

		this.toastInfo.dom = document.createElement('div')
		this.toastInfo.dom.classList.add('dimina-toast', `dimina-toast--${icon}`)
		this.toastInfo.dom.innerHTML = `<p>${title}</p>`
		this.webviewsContainer.appendChild(this.toastInfo.dom)

		this.toastInfo.timer = setTimeout(() => {
			this.webviewsContainer.removeChild(this.toastInfo.dom)
			this.toastInfo.dom = null
		}, duration)

		onSuccess?.()
		onComplete?.()
	}

	hideToast(opts) {
		const { success, complete } = opts
		const onSuccess = this.createCallbackFunction(success)
		const onComplete = this.createCallbackFunction(complete)

		if (this.toastInfo.dom) {
			this.webviewsContainer.removeChild(this.toastInfo.dom)
			this.toastInfo.dom = null
		}
		if (this.toastInfo.timer) {
			clearTimeout(this.toastInfo.timer)
			this.toastInfo.timer = null
		}
		onSuccess?.()
		onComplete?.()
	}

	showLoading(opts) {
		this.showToast({ ...opts, icon: 'loading' })
	}

	hideLoading(opts) {
		this.hideLoading(opts)
	}

	showModal(opts) {
		const { content = '', cancelText = '取消', confirmText = '确定', success, complete } = opts

		const onSuccess = this.createCallbackFunction(success)
		const onComplete = this.createCallbackFunction(complete)

		const dialog = document.createElement('dialog')
		dialog.setAttribute('class', 'dimina-dialog')
		dialog.innerHTML = `<p>${content}</p>
		<div>
			<a id="cancelBtn" class="dimina-dialog__button" href="javascript:">${cancelText}</a>
			<a id="confirmBtn" class="dimina-dialog__button" style="color: #576b95;" href="javascript:">${confirmText}</a>
    	</div>
  		`

		dialog.querySelector('#cancelBtn').addEventListener('click', () => {
			dialog.hidden = true
			this.webviewsContainer.removeChild(dialog)
			onSuccess?.({ cancel: true })
			onComplete?.()
		})

		dialog.querySelector('#confirmBtn').addEventListener('click', () => {
			dialog.hidden = true
			this.webviewsContainer.removeChild(dialog)
			onSuccess?.({ confirm: true })
			onComplete?.()
		})

		this.webviewsContainer.appendChild(dialog)
		dialog.showModal()
	}

	showActionSheet(opts) {
		const { itemList = [], itemColor = '#000', success, fail, complete } = opts || {};
		if (!Array.isArray(itemList) || itemList.length === 0) {
			fail && this.createCallbackFunction(fail)({ errMsg: 'showActionSheet:fail' });
			complete && this.createCallbackFunction(complete)();
			return;
		}
		// 创建遮罩层
		const mask = document.createElement('div');
		mask.className = 'dimina-action-sheet-mask';
		// 创建 action sheet 容器
		const sheet = document.createElement('div');
		sheet.className = 'dimina-action-sheet';
		// 选项
		itemList.forEach((item, idx) => {
			const btn = document.createElement('div');
			btn.className = 'dimina-action-sheet-item';
			btn.style.color = itemColor;
			btn.innerText = item;
			btn.onclick = () => {
				cleanup();
				success && this.createCallbackFunction(success)({ tapIndex: idx });
				complete && this.createCallbackFunction(complete)();
			};
			sheet.appendChild(btn);
		});
		// 取消按钮
		const cancelBtn = document.createElement('div');
		cancelBtn.className = 'dimina-action-sheet-cancel';
		cancelBtn.innerText = '取消';
		cancelBtn.onclick = () => {
			cleanup();
			fail && this.createCallbackFunction(fail)({ errMsg: 'showActionSheet:fail cancel' });
			complete && this.createCallbackFunction(complete)();
		};
		sheet.appendChild(cancelBtn);
		// 清理方法
		const cleanup = () => {
			mask.remove();
			sheet.remove();
		};
		mask.onclick = cleanup;
		// 挂载到 webviewsContainer
		this.webviewsContainer.appendChild(mask);
		this.webviewsContainer.appendChild(sheet);
		console.log(12345, itemList)
		// 动画效果
		setTimeout(() => {
			sheet.classList.add('show');
			mask.classList.add('show');
		}, 10);
	}
}
