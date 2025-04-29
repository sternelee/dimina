<script setup>
// 视图容器
// https://developers.weixin.qq.com/miniprogram/dev/component/view.html
import { triggerEvent, useInfo } from '@/common/events'
import { useLongPress } from '@/common/useLongPress'

const info = useInfo()

function onClicked(event) {
	triggerEvent('tap', { event, info })
}

// 使用公共的长按逻辑
// 传入组件信息、长按时间阈值和移动距离阈值
const { onTouchStart, onTouchMove, onTouchEnd, onTouchCancel } = useLongPress(info)
</script>

<template>
	<div
		v-bind="$attrs" class="dd-view" @click="onClicked" @touchstart="onTouchStart" @touchmove="onTouchMove"
		@touchend="onTouchEnd" @touchcancel="onTouchCancel"
	>
		<slot />
	</div>
</template>

<style lang="scss">
.dd-view {
	display: block;

	&[hidden] {
		display: none;
	}
}
</style>
