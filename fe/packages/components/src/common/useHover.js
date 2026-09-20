import { isHoverScrolling, trackHoverScroll } from './hoverScrollState'
import { DEFAULT_MOVE_THRESHOLD, firstPoint, pointWithIdentifier } from './touchGesturePrimitives'

/**
 * Implements the hover-class behavior shared by view-like components.
 *
 * exparser marks the original touch event instead of stopping DOM propagation,
 * so hover-stop-propagation only suppresses ancestor hover states and does not
 * swallow tap/touch handlers.
 */
export function useHover(props) {
	const isHover = ref(false)
	let isPressed = false
	let startTimer
	let stayTimer
	let startPoint
	let pressedElement
	let scrollDocument
	let releaseScrollTracking

	onMounted(() => {
		releaseScrollTracking = trackHoverScroll(document)
	})

	function clearStartTimer() {
		if (startTimer !== undefined) {
			clearTimeout(startTimer)
			startTimer = undefined
		}
	}

	function clearStayTimer() {
		if (stayTimer !== undefined) {
			clearTimeout(stayTimer)
			stayTimer = undefined
		}
	}

	function resetHover() {
		clearStartTimer()
		clearStayTimer()
		isHover.value = false
		scrollDocument?.removeEventListener('scroll', onScroll, true)
		scrollDocument = undefined
		pressedElement = undefined
		startPoint = undefined
	}

	function start(event) {
		if (event._ddHoverPropagationStopped) {
			return
		}
		if (props.hoverStopPropagation) {
			event._ddHoverPropagationStopped = true
		}

		cancel()
		if (isHoverScrolling(event.currentTarget)) return
		if (props.disabled || props.hoverClass === 'none') {
			return
		}
		if (event.touches?.length > 1) {
			return
		}

		isPressed = true
		startPoint = event.touches ? firstPoint(event.touches, event.changedTouches) : event
		pressedElement = event.currentTarget
		scrollDocument = pressedElement?.ownerDocument
		// scroll 不冒泡，捕获阶段只关注当前控件所在的滚动容器。
		scrollDocument?.addEventListener('scroll', onScroll, { capture: true, passive: true })

		startTimer = setTimeout(() => {
			startTimer = undefined
			isHover.value = true
			if (!isPressed) {
				stayTimer = setTimeout(resetHover, Number(props.hoverStayTime) || 0)
			}
		}, Math.max(Number(props.hoverStartTime) || 0, 0))
	}

	function onScroll(event) {
		if (event.target === scrollDocument || event.target?.contains?.(pressedElement)) {
			cancel()
		}
	}

	function move(event) {
		if (!isPressed || !startPoint) return
		const point = event.touches
			? pointWithIdentifier(startPoint.identifier, event.touches, event.changedTouches)
			: event
		if (event.touches?.length > 1 || !point
			|| Math.abs(point.clientX - startPoint.clientX) >= DEFAULT_MOVE_THRESHOLD
			|| Math.abs(point.clientY - startPoint.clientY) >= DEFAULT_MOVE_THRESHOLD) {
			cancel()
		}
	}

	function end(event) {
		// 部分 WebView 可能没有派发中间的 move，结束时仍要复查位移。
		if (event) move(event)
		isPressed = false
		if (isHover.value) {
			clearStayTimer()
			stayTimer = setTimeout(resetHover, Math.max(Number(props.hoverStayTime) || 0, 0))
		}
	}

	function cancel() {
		isPressed = false
		resetHover()
	}

	onBeforeUnmount(() => {
		cancel()
		releaseScrollTracking?.()
	})

	return {
		isHover,
		onHoverCancel: cancel,
		onHoverEnd: end,
		onHoverMove: move,
		onHoverStart: start,
	}
}
