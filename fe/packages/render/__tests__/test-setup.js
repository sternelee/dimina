// 模拟 DiminaRenderBridge
window.DiminaRenderBridge = {
	onMessage: null,
	publish: () => {},
	invoke: () => {},
}

// 屏蔽测试中不必要的日志
globalThis.console = {
	...console,
	log: () => {},
	warn: () => {},
	error: () => {},
}
