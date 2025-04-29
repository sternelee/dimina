<script setup>
// 视频
// https://developers.weixin.qq.com/miniprogram/dev/component/video.html

const props = defineProps({
	/**
	 * 要播放视频的资源地址，支持网络路径、本地临时路径
	 */
	src: {
		type: String,
		required: true,
	},
	/**
	 * 指定视频时长
	 */
	duration: {
		type: Number,
		required: false,
	},
	/**
	 * 是否显示默认播放控件（播放/暂停按钮、播放进度、时间）
	 */
	controls: {
		type: Boolean,
		required: false,
		default: true,
	},
})
</script>

<template>
	<div v-bind="$attrs" />
</template>

<style lang="scss">
</style>
