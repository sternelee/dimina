<script setup>
// 页面属性配置节点，用于指定页面的一些属性、监听页面事件。只能是页面内的第一个节点。可以配合 navigation-bar 组件一同使用。
// 通过这个节点可以获得类似于调用 wx.setBackgroundTextStyle wx.setBackgroundColor 等接口调用的效果。
// https://developers.weixin.qq.com/miniprogram/dev/component/page-meta.html

import { invokeAPI, useInfo } from '@/common/events'

const props = defineProps({
	/**
	 * 下拉背景字体、loading 图的样式，仅支持 dark 和 light
	 */
	backgroundTextStyle: {
		type: String,
		required: false,
		validator: (value) => {
			return ['dark', 'light'].includes(value)
		},
	},
	/**
	 * 窗口的背景色，必须为十六进制颜色值
	 */
	backgroundColor: {
		type: String,
		required: false,
	},
	/**
	 * 窗口的背景色，必须为十六进制颜色值
	 */
	backgroundColorTop: {
		type: String,
		required: false,
	},
	/**
	 * 底部窗口的背景色，必须为十六进制颜色值，仅 iOS 支持
	 */
	backgroundColorBottom: {
		type: String,
		required: false,
	},
	/**
	 * 页面内容的背景色，用于页面中的空白部分和页面大小变化 resize 动画期间的临时空闲区域
	 */
	rootBackgroundColor: {
		type: String,
		default: '',
		required: false,
	},
	/**
	 * 页面根节点样式，页面根节点是所有页面节点的祖先节点，相当于 HTML 中的 body 节点
	 */
	pageStyle: {
		type: String,
		default: '',
		required: false,
	},
	/**
	 * 页面 page 的字体大小，可以设置为 system ，表示使用当前用户设置的微信字体大小
	 */
	pageFontSize: {
		type: String,
		default: '',
		required: false,
	},
	/**
	 * 页面的根字体大小，页面中的所有 rem 单位，将使用这个字体大小作为参考值，即 1rem 等于这个字体大小；自小程序版本 2.11.0 起，也可以设置为 system
	 */
	rootFontSize: {
		type: String,
		default: '',
		required: false,
	},
	/**
	 * 页面的方向，可为 auto portrait 或 landscape
	 */
	pageOrientation: {
		type: String,
		default: '',
		required: false,
	},
})

const info = useInfo()
onMounted(() => {
	invokeAPI('setBackgroundTextStyle', {
		bridgeId: info.bridgeId,
		params: { textStyle: props.backgroundTextStyle },
	})

	invokeAPI('setBackgroundColor', {
		bridgeId: info.bridgeId,
		params: {
			backgroundColor: props.backgroundColor,
			backgroundColorTop: props.backgroundColorTop,
			backgroundColorBottom: props.backgroundColorBottom,
		},
	})
})
</script>

<template>
	<slot />
</template>
