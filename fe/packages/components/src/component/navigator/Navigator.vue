<script setup>
// https://developers.weixin.qq.com/miniprogram/dev/component/navigator.html

import { parsePath, sleep } from '@dimina/common'
import { invokeAPI, useInfo } from '@/common/events'

const props = defineProps({
	/**
	 * 在哪个目标上发生跳转，默认当前小程序
	 * 合法值 self|miniProgram
	 */
	target: {
		type: String,
		default: 'self',
	},
	url: {
		type: String,
	},
	redirect: {
		type: Boolean,
		default: false,
	},
	/**
	 * 跳转方式
	 * 合法值: navigate, redirect, switchTab, reLaunch, navigateBack, exit
	 */
	openType: {
		type: String,
		default: 'navigate',
	},
	/**
	 * 当 open-type 为 'navigateBack' 时有效，表示回退的层数
	 */
	delta: {
		type: Number,
		default: 1,
	},
	/**
	 * 当target="miniProgram"且open-type="navigate"时有效，要打开的小程序 appId
	 */
	appId: {
		type: String,
	},
	// 当target="miniProgram"且open-type="navigate"时有效，打开的页面路径，如果为空则打开首页
	path: {
		type: String,
	},
	// 当target="miniProgram"且open-type="navigate/navigateBack"时有效，需要传递给目标小程序的数据，目标小程序可在 App.onLaunch()，App.onShow() 中获取到这份数据
	extraData: {
		type: Object,
	},
	/**
	 * 当target="miniProgram"且open-type="navigate"时有效，要打开的小程序版本
	 * 合法值 develop|trial|release
	 */
	version: {
		type: String,
		default: 'release',
	},
	/**
	 * 当target="miniProgram"时有效，当传递该参数后，可以不传 app-id 和 path。链接可以通过【小程序菜单】->【复制链接】获取。
	 */
	shortLink: {
		type: String,
	},
	/**
	 * 指定点击时的样式类，当hover-class="none"时，没有点击态效果
	 */
	hoverClass: {
		type: String,
		default: 'navigator-hover',
	},
	/**
	 * 指定是否阻止本节点的祖先节点出现点击态
	 */
	hoverStopPropagation: {
		type: Boolean,
		default: false,
	},
	/**
	 * 按住后多久出现点击态，单位毫秒
	 */
	hoverStartTime: {
		type: Number,
		default: 50,
	},
	/**
	 * 手指松开后点击态保留时间，单位毫秒
	 */
	hoverStayTime: {
		type: Number,
		default: 600,
	},
})

const isActive = ref(false)

async function handleDown(event) {
	if (props.hoverStopPropagation) {
		event.stopPropagation()
	}
	await sleep(props.hoverStartTime)
	isActive.value = true
}

async function handleUp() {
	await sleep(props.hoverStayTime)
	isActive.value = false
}

const info = useInfo()
function clicked() {
	const { openType, target, url, redirect } = props
	if (url?.includes('javascript:')) {
		return
	}
	if (redirect) {
		invokeAPI('redirectTo', {
			bridgeId: info.bridgeId,
			params: { url: parsePath(info.path, url) },
		})
		return
	}

	switch (openType) {
		case 'navigate': {
			invokeAPI('navigateTo', {
				bridgeId: info.bridgeId,
				params: { url: parsePath(info.path, url) },
			})
			break
		}
		case 'redirect': {
			invokeAPI('redirectTo', {
				bridgeId: info.bridgeId,
				params: { url: parsePath(info.path, url) },
			})
			break
		}
		case 'switchTab': {
			invokeAPI('switchTab', {
				bridgeId: info.bridgeId,
				params: { url: parsePath(info.path, url) },
			})
			break
		}
		case 'reLaunch': {
			invokeAPI('reLaunch', {
				bridgeId: info.bridgeId,
				params: { url: parsePath(info.path, url) },
			})
			break
		}
		case 'navigateBack': {
			invokeAPI('navigateBack', {
				bridgeId: info.bridgeId,
			})
			break
		}
		case 'exit': {
			if (target === 'miniProgram') {
				invokeAPI('exit', {
					bridgeId: info.bridgeId,
				})
			}
			break
		}
	}
}
</script>

<template>
	<span
		v-bind="$attrs" class="dd-navigator" :class="[isActive ? hoverClass : undefined]" @click="clicked"
		@mousedown="handleDown" @mouseup="handleUp"
	>
		<slot />
	</span>
</template>

<style lang="scss">
.dd-navigator {
	height: auto;
	width: auto;
	display: block;

	&.navigator-hover {
		background-color: rgba(0, 0, 0, 0.1);
		opacity: 0.7;
	}

	&[hidden] {
		display: none;
	}
}
</style>
