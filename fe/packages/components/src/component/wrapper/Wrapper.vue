<script setup>
import { useInfo } from '@/common/events'

useInfo()

const wrapperRef = ref(null)

onMounted(() => {
	// 只检查直接的插槽内容节点
	const slotContent = wrapperRef.value?.firstElementChild
	if (slotContent) {
		const style = window.getComputedStyle(slotContent)
		// 检查是否为 sticky 定位且设置了位置值
		if (style.position === 'sticky'
			&& (style.top !== 'auto'
				|| style.bottom !== 'auto'
				|| style.left !== 'auto'
				|| style.right !== 'auto')) {
			wrapperRef.value.style.display = 'contents'
		}
	}
})
// 自定义组件需要该组件接收点击事件定义，相关事件将在 render 中处理
</script>

<template>
	<div v-bind="$attrs" ref="wrapperRef">
		<slot />
	</div>
</template>
