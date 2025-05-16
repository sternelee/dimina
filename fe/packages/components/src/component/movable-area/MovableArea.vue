<script setup>
// movable-area的可移动区域
// https://developers.weixin.qq.com/miniprogram/dev/component/movable-area.html

import { triggerEvent, useInfo } from '@/common/events'

defineProps({
	/**
	 * 当里面的movable-view设置为支持双指缩放时，设置此值可将缩放手势生效区域修改为整个movable-area
	 */
	scaleArea: {
		type: Boolean,
		default: false,
		require: false,
	},
})

const info = useInfo()

function onClicked(event) {
	triggerEvent('tap', { event, info })
}
</script>

<template>
	<div v-bind="$attrs" class="dd-movable-area" @click="onClicked">
		<slot />
	</div>
</template>

<style lang="scss">
.dd-movable-area {
	display: block;
	position: relative;
	width: 10px;
	height: 10px;

	&[hidden] {
		display: none;
	}
}
</style>
