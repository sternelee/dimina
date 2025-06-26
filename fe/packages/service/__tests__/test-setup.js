// 模拟 DiminaServiceBridge
globalThis.DiminaServiceBridge = {
	onMessage: null,
	sendMessage: () => {},
	publish: () => Promise.resolve()
}

// 模拟 console 方法以避免测试输出过多日志
globalThis.console = {
	...console,
	log: () => {},
	warn: () => {},
	error: () => {}
} 
