import { triggerEvent } from './events'

/**
 * 长按事件处理的可复用逻辑
 * @param {object} info 组件信息
 * @param {number} threshold 长按触发阈值，单位毫秒
 * @param {number} moveThreshold 判定为移动的阈值，单位像素
 * @returns {object} 长按相关的方法和状态
 */
export function useLongPress(info, threshold = 350, moveThreshold = 10) {
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
				// 创建新的事件对象，确保 currentTarget 被保留
				triggerEvent('longpress', { event: { ...event, currentTarget }, info })
				// 兼容性处理，同时触发 longtap 事件
				// triggerEvent('longtap', { event: { ...event, currentTarget }, info })
			}
			longPressTimer.value = null
		}, threshold)

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

	return {
		onTouchStart,
		onTouchMove,
		onTouchEnd,
		onTouchCancel,
	}
}
