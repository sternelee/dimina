// 祖先最近 50ms 内发生过滚动时，不启动点击态。
const SCROLL_QUIET_TIME = 50
const documents = new WeakMap()

export function trackHoverScroll(document) {
	let state = documents.get(document)
	if (!state) {
		const timestamps = new WeakMap()
		const onScroll = event => timestamps.set(event.target, Date.now())
		state = { timestamps, onScroll, users: 0 }
		documents.set(document, state)
		document.addEventListener('scroll', onScroll, { capture: true, passive: true })
	}
	state.users++
	return () => {
		if (--state.users === 0) {
			document.removeEventListener('scroll', state.onScroll, true)
			documents.delete(document)
		}
	}
}

export function isHoverScrolling(element) {
	const state = documents.get(element?.ownerDocument)
	if (!state) return false
	const now = Date.now()
	for (let node = element; node; node = node.parentNode || node.host) {
		const timestamp = state.timestamps.get(node)
		if (timestamp !== undefined && now - timestamp < SCROLL_QUIET_TIME) return true
	}
	return false
}
