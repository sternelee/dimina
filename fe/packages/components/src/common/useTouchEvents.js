import { hasCatchEvent, triggerEvent } from './events'

/**
 * 处理组件的触摸相关事件
 * 封装了触摸事件的添加、移除和检测catch事件处理器的逻辑
 * @param {object} info 组件信息
 * @param {object} elementRef 元素引用
 * @param {number} longPressThreshold 长按触发阈值，单位毫秒
 * @param {number} moveThreshold 判定为移动的阈值，单位像素
 */
export function useTouchEvents(info, elementRef, longPressThreshold = 350, moveThreshold = 10) {
	// 长按相关状态
	const longPressTimer = ref(null)
	const touchStartPosition = ref({ x: 0, y: 0 })
	const isTouchMoved = ref(false)

	/**
	 * 触摸开始事件处理
	 * @param {Event} event 原始事件对象
	 */
	function onTouchStart(event) {
		// currentTarget 在异步回调中可能为空，此处保存引用
		const currentTarget = event.currentTarget
		const touch = event.touches[0]
		touchStartPosition.value = { x: touch.clientX, y: touch.clientY }
		isTouchMoved.value = false

		// 清除可能存在的定时器
		if (longPressTimer.value) {
			clearTimeout(longPressTimer.value)
		}

		// 设置长按定时器
		longPressTimer.value = setTimeout(() => {
			// 如果触摸没有移动太多，则触发长按事件
			if (!isTouchMoved.value) {
				// 创建新的事件对象，确保 currentTarget 被保留，未实现 longtap
				triggerEvent('longpress', { event: { ...event, currentTarget }, info })
			}
			longPressTimer.value = null
		}, longPressThreshold)

		triggerEvent('touchstart', { event, info })
	}

	/**
	 * 触摸移动事件处理
	 * @param {Event} event 原始事件对象
	 */
	function onTouchMove(event) {
		const touch = event.touches[0]
		const moveX = Math.abs(touch.clientX - touchStartPosition.value.x)
		const moveY = Math.abs(touch.clientY - touchStartPosition.value.y)

		// 如果移动距离超过阈值，则标记为已移动
		if (moveX > moveThreshold || moveY > moveThreshold) {
			isTouchMoved.value = true

			// 如果移动了，取消长按定时器
			if (longPressTimer.value) {
				clearTimeout(longPressTimer.value)
				longPressTimer.value = null
			}
		}

		triggerEvent('touchmove', { event, info })
	}

	/**
	 * 触摸结束事件处理
	 * @param {Event} event 原始事件对象
	 */
	function onTouchEnd(event) {
		// 清除长按定时器
		if (longPressTimer.value) {
			clearTimeout(longPressTimer.value)
			longPressTimer.value = null
		}

		triggerEvent('touchend', { event, info })
	}

	/**
	 * 触摸取消事件处理
	 * @param {Event} event 原始事件对象
	 */
	function onTouchCancel(event) {
		// 清除长按定时器
		if (longPressTimer.value) {
			clearTimeout(longPressTimer.value)
			longPressTimer.value = null
		}

		triggerEvent('touchcancel', { event, info })
	}

	// 检查是否有catch事件处理器
	// 支持写法：catchtouchstart、catch:touchstart
	const hasCatchTouchStart = hasCatchEvent(info, 'touchstart')
	const hasCatchTouchMove = hasCatchEvent(info, 'touchmove')
	const hasCatchTouchEnd = hasCatchEvent(info, 'touchend')
	const hasCatchTouchCancel = hasCatchEvent(info, 'touchcancel')

	// 在组件挂载时添加事件监听器
	onMounted(() => {
		if (elementRef.value) {
			elementRef.value.addEventListener('touchstart', onTouchStart, { passive: !hasCatchTouchStart })
			elementRef.value.addEventListener('touchmove', onTouchMove, { passive: !hasCatchTouchMove })
			elementRef.value.addEventListener('touchend', onTouchEnd, { passive: !hasCatchTouchEnd })
			elementRef.value.addEventListener('touchcancel', onTouchCancel, { passive: !hasCatchTouchCancel })
		}
	})

	// 在组件卸载时移除事件监听器
	onUnmounted(() => {
		if (elementRef.value) {
			elementRef.value.removeEventListener('touchstart', onTouchStart, { passive: !hasCatchTouchStart })
			elementRef.value.removeEventListener('touchmove', onTouchMove, { passive: !hasCatchTouchMove })
			elementRef.value.removeEventListener('touchend', onTouchEnd, { passive: !hasCatchTouchEnd })
			elementRef.value.removeEventListener('touchcancel', onTouchCancel, { passive: !hasCatchTouchCancel })
		}
	})
}
