import VConsole from 'vconsole'

interface VConsolePosition {
	x?: number
	y?: number
}

function addMiniProgramStorage(vConsole: VConsole) {
	const plugin = new VConsole.VConsolePlugin('dimina-storage', 'MiniProgram Storage')
	const content = document.createElement('pre')
	content.style.cssText = 'padding:10px;white-space:pre-wrap;overflow-wrap:anywhere'
	content.textContent = 'Open this tab to read mini-program storage.'
	const refresh = () => {
		content.textContent = 'Loading…'
		window.dispatchEvent(new Event('dimina:debug-storage-request'))
	}
	const update = (event: Event) => {
		const { value, error } = (event as CustomEvent).detail
		content.textContent = error || JSON.stringify(value, null, 2)
	}
	plugin.on('renderTab', (callback: (element: HTMLElement) => void) => callback(content))
	plugin.on('show', refresh)
	plugin.on('addTool', (callback: (tools: unknown[]) => void) => callback([
		{ name: 'Refresh', global: false, onClick: refresh },
	]))
	plugin.on('remove', () => window.removeEventListener('dimina:debug-storage', update))
	window.addEventListener('dimina:debug-storage', update)
	vConsole.addPlugin(plugin)
}

function setupVConsole(options: VConsolePosition = {}) {
	if (!window.vConsole) {
		const vConsole = new VConsole()
		vConsole.setSwitchPosition(options.x ?? 10, options.y ?? 140)
		window.vConsole = vConsole
		window.addEventListener('dimina:debug-ready', () => addMiniProgramStorage(vConsole), { once: true })
	}
	return window.vConsole!
}

window.__dimina_enable_vconsole__ = function enableVConsole(options: VConsolePosition = {}) {
	return Promise.resolve(setupVConsole(options))
}

if (new URLSearchParams(window.location.search).get('vconsole') === '1') {
	window.__dimina_enable_vconsole__()
}
