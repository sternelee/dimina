import tpl from './device.html?raw'
import '../../../tokens.css'
import './device-stage.scss'
import './device.scss'
import diminaLogo from '@/assets/dimina-logo.png'

const ORBIT_LIGHT_FOLLOW_FACTOR = 0.08
const ORBIT_LIGHT_INNER_THRESHOLD = 0.75
const ORBIT_LIGHT_SETTLE_THRESHOLD = 0.1

export class Device {
	constructor() {
		this.appContainer = null
		this.application = null
		this.isScreenSleeping = false
		this.root = document.querySelector('#root')
		this.init()
	}

	init() {
		this.root.innerHTML = tpl
		this.root.querySelector('.device-stage__logo')?.setAttribute('src', diminaLogo)

		this.appContainer = this.root.querySelector('.iphone__apps')
		this.updateStatusBarColor('black')
		this.updateStatusBarTime()
		this.bindDynamicIsland()
		this.bindStageGlow()
		this.bindPowerButton()
	}

	updateStatusBarTime() {
		const timeElement = this.root.querySelector('.status-bar__time')

		const updateTime = () => {
			const now = new Date()
			const hours = now.getHours().toString().padStart(2, '0')
			const minutes = now.getMinutes().toString().padStart(2, '0')
			timeElement.textContent = `${hours}:${minutes}`
		}

		// 立即更新一次
		updateTime()

		// 每分钟更新一次（60000毫秒 = 1分钟）
		setInterval(updateTime, 60000)
	}

	bindDynamicIsland() {
		const island = this.root.querySelector('.iphone__screen_dynamic-island')
		island.addEventListener('click', () => {
			window.open('https://github.com/didi/dimina', '_blank')
		})

		// 鼠标进入灵动岛时放大效果
		island.addEventListener('mouseenter', () => {
			// 使用CSS类来添加缩放效果，而不是直接设置transform
			island.classList.add('island-hover')
		})

		// 鼠标离开灵动岛时恢复大小
		island.addEventListener('mouseleave', () => {
			// 移除CSS类来恢复大小
			island.classList.remove('island-hover')
		})
	}

	bindStageGlow() {
		const stage = this.root.querySelector('.device-stage')
		const orbit = this.root.querySelector('.device-stage__orbit')
		let pendingPointer = null
		let pointerFrame = 0
		let orbitLightAngle = 45
		let targetOrbitLightAngle = orbitLightAngle

		const renderPointer = () => {
			if (pendingPointer) {
				const { pointerX, pointerY } = pendingPointer
				const orbitRect = orbit.getBoundingClientRect()
				const centerX = orbitRect.left + orbitRect.width / 2
				const centerY = orbitRect.top + orbitRect.height / 2
				const deltaX = pointerX - centerX
				const deltaY = pointerY - centerY
				const orbitRadius = Math.min(orbitRect.width, orbitRect.height) / 2

				// 旧版光斑只有靠近环线时才会明显影响光弧；忽略圆心附近的极角抖动。
				if (Math.hypot(deltaX, deltaY) >= orbitRadius * ORBIT_LIGHT_INNER_THRESHOLD) {
					const angle = Math.atan2(deltaY, deltaX) * 180 / Math.PI + 90
					const shortestTurn = (angle - targetOrbitLightAngle + 540) % 360 - 180
					targetOrbitLightAngle += shortestTurn
				}
				pendingPointer = null
			}

			const remainingTurn = targetOrbitLightAngle - orbitLightAngle
			if (Math.abs(remainingTurn) <= ORBIT_LIGHT_SETTLE_THRESHOLD) {
				orbitLightAngle = targetOrbitLightAngle
				stage.style.setProperty('--orbit-light-angle', `${orbitLightAngle.toFixed(2)}deg`)
				pointerFrame = 0
				return
			}

			orbitLightAngle += remainingTurn * ORBIT_LIGHT_FOLLOW_FACTOR
			stage.style.setProperty('--orbit-light-angle', `${orbitLightAngle.toFixed(2)}deg`)
			pointerFrame = requestAnimationFrame(renderPointer)
		}

		const syncPointer = ({ x: pointerX, y: pointerY }) => {
			pendingPointer = { pointerX, pointerY }
			if (pointerFrame) {
				return
			}

			pointerFrame = requestAnimationFrame(renderPointer)
		}
		const stageRect = stage.getBoundingClientRect()
		syncPointer({
			x: stageRect.left + stageRect.width * 0.62,
			y: stageRect.top + stageRect.height * 0.24,
		})
		this.root.addEventListener('pointermove', syncPointer)
	}

	bindPowerButton() {
		const powerButton = this.root.querySelector('.power-btn')

		powerButton?.addEventListener('pointerdown', (event) => {
			event.preventDefault()
			this.toggleScreen()
		})

		powerButton?.addEventListener('keydown', (event) => {
			if (event.repeat || (event.key !== 'Enter' && event.key !== ' ')) {
				return
			}

			event.preventDefault()
			this.toggleScreen()
		})
	}

	toggleScreen() {
		if (this.isScreenSleeping) {
			this.wakeScreen()
		}
		else {
			this.sleepScreen()
		}
	}

	sleepScreen() {
		if (this.isScreenSleeping) {
			return
		}

		this.isScreenSleeping = true
		this.root.querySelector('.iphone__screen')?.classList.add('iphone__screen--sleeping')
		this.root.querySelector('.power-btn')?.setAttribute('aria-pressed', 'true')
		this.application?.sleepActiveView?.()
	}

	wakeScreen() {
		if (!this.isScreenSleeping) {
			return
		}

		this.isScreenSleeping = false
		this.root.querySelector('.iphone__screen')?.classList.remove('iphone__screen--sleeping')
		this.root.querySelector('.power-btn')?.setAttribute('aria-pressed', 'false')
		this.application?.wakeActiveView?.()
	}

	// black white
	// 实现 container-sdk 的 shell.updateStatusBarColor 接口（见 createContainer 契约）
	updateStatusBarColor(color) {
		const statusBar = this.root.querySelector('.iphone__status-bar')

		if (color === 'black') {
			statusBar.classList.remove('iphone__status-bar--white')
			statusBar.classList.add('iphone__status-bar--black')
		}
		else if (color === 'white') {
			statusBar.classList.add('iphone__status-bar--white')
			statusBar.classList.remove('iphone__status-bar--black')
		}
	}

	// 实现 container-sdk 的 shell.getStatusBarRect 接口（见 createContainer 契约）
	getStatusBarRect() {
		return this.root.querySelector('.iphone__status-bar').getBoundingClientRect()
	}

	// 只记录当前承载的 Application 实例，供锁屏/亮屏时联动挂起/恢复视图使用；
	// DOM 挂载由 createContainer({ mount: device.appContainer }) 负责，这里不重复处理。
	open(app) {
		this.application = app
	}
}
