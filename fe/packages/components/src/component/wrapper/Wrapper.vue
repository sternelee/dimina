<script setup>
import { useInfo } from '@/common/events'

useInfo()

const wrapperRef = ref(null)

// 检查并继承sticky样式的函数，修复 sticky 样式被 wrapper 节点隔离后不生效的问题
function inheritStickyStyle() {
	// 只检查直接的插槽内容节点
	const slotContent = wrapperRef.value?.firstElementChild
	if (!slotContent || typeof window === 'undefined') {
		return
	}

	// 获取子节点的计算样式
	const computedStyle = window.getComputedStyle(slotContent)

	// 检查子节点是否有 sticky 定位
	if (computedStyle.position === 'sticky') {
		// 检查是否至少有一个方向的值不是auto
		let hasNonAutoValue = false
		const stickyProps = ['top', 'bottom', 'left', 'right']

		// 继承 top, bottom, left, right 值
		stickyProps.forEach((prop) => {
			const value = computedStyle[prop]
			if (value && value !== 'auto') {
				hasNonAutoValue = true
			}
		})

		// 只有当至少有一个方向的值不是auto时才设置 position: sticky
		if (hasNonAutoValue) {
			wrapperRef.value.style.display = 'contents'
		}
	}
}

onMounted(inheritStickyStyle)
// 自定义组件需要该组件接收点击事件定义，相关事件将在 render 中处理
</script>

<template>
	<div v-bind="$attrs" ref="wrapperRef">
		<slot />
	</div>
</template>
