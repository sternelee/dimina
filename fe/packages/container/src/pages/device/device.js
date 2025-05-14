import './device.scss'
import tpl from './device.html?raw'

export class Device {
	constructor() {
		this.appContainer = null
		this.root = document.querySelector('#root')
		this.init()
	}

	init() {
		const envVar = import.meta.env
		// 替换环境变量
		this.root.innerHTML = tpl.replace(
			/<%=\s*(\w+)\s*%>/g,
			(_, p1) => envVar[p1] || '',
		)

		this.appContainer = this.root.querySelector('.iphone__apps')
		this.updateDeviceBarColor('black')
		this.outerGlow()
	}

	outerGlow() {
		const island = this.root.querySelector('.iphone__screen_dynamic-island')
		island.addEventListener('click', () => {
			window.open('https://github.com/didi/dimina', '_blank')
		})
		const syncPointer = ({ x: pointerX, y: pointerY }) => {
			const x = pointerX.toFixed(2)
			const y = pointerY.toFixed(2)
			const xp = (pointerX / window.innerWidth).toFixed(2)
			const yp = (pointerY / window.innerHeight).toFixed(2)
			document.documentElement.style.setProperty('--x', x)
			document.documentElement.style.setProperty('--xp', xp)
			document.documentElement.style.setProperty('--y', y)
			document.documentElement.style.setProperty('--yp', yp)
		}
		document.body.addEventListener('pointermove', syncPointer)
	}

	// black white
	updateDeviceBarColor(color) {
		const statusBar = this.root.querySelector('.iphone__status-bar')
		const homeBar = this.root.querySelector('.iphone__home-touch-bar')

		if (color === 'black') {
			statusBar.classList.remove('iphone__status-bar--white')
			statusBar.classList.add('iphone__status-bar--black')

			homeBar.classList.remove('iphone__home-touch-bar--white')
			homeBar.classList.add('iphone__home-touch-bar--black')
		}
		else if (color === 'white') {
			statusBar.classList.add('iphone__status-bar--white')
			statusBar.classList.remove('iphone__status-bar--black')

			homeBar.classList.add('iphone__home-touch-bar--white')
			homeBar.classList.remove('iphone__home-touch-bar--black')
		}
	}

	open(app) {
		app.parent = this
		this.appContainer.appendChild(app.el)
	}
}
