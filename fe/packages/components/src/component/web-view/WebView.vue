<script setup>
// 承载网页的容器
// https://developers.weixin.qq.com/miniprogram/dev/component/web-view.html
import { isDesktop } from '@dimina/common'
import { invokeAPI, offEvent, onEvent, triggerEvent, useInfo } from '@/common/events'

const props = defineProps({
	/**
	 * webview id
	 */
	id: {
		type: String,
		default: `web-view_${Date.now()}_${String(Math.random()).slice(-3)}`,
	},
	/**
	 *	webview 指向网页的链接
	 */
	src: {
		type: String,
	},
})

const ENCODE_CHARS_REGEXP = /(?:[^\x21\x25\x26-\x3B\x3D\x3F-\x5B\x5D\x5F\x7E]|%(?:[^0-9A-F]|[0-9A-F][^0-9A-F]|$))+/gi

const UNMATCHED_SURROGATE_PAIR_REGEXP = /(^|[^\uD800-\uDBFF])[\uDC00-\uDFFF]|[\uD800-\uDBFF]([^\uDC00-\uDFFF]|$)/g

const UNMATCHED_SURROGATE_PAIR_REPLACE = '$1\uFFFD$2'

const url = computed(() => {
	return String(props.src)
		.replace(UNMATCHED_SURROGATE_PAIR_REGEXP, UNMATCHED_SURROGATE_PAIR_REPLACE)
		.replace(ENCODE_CHARS_REGEXP, encodeURI)
})

const type = 'native/webview'
const info = useInfo()
const attrs = info.attrs

function getEventAttrs() {
	const eventAttrs = {}
	for (const attrName in attrs) {
		if (attrName.startsWith('bind') || attrName.startsWith('catch')) {
			eventAttrs[attrName.replace(/^(?:bind:|bind|catch:|catch)/, '')] = attrs[attrName]
		}
	}
	return eventAttrs
}

watch(
	[
		() => props.src,
		() => props.id,
	],
	(
		[newSrc, newId],
	) => {
		invokeAPI('propsUpdate', {
			bridgeId: info.bridgeId,
			params: {
				type,
				src: newSrc,
				id: newId,
			},
		})
	},
)

onBeforeMount(() => {
	onEvent('bindmessage', (msg) => {
		triggerEvent('message', {
			type: 'message',
			info,
			detail: {
				data: msg.data,
			},
		})
	})

	onEvent('bindload', (msg) => {
		triggerEvent('load', {
			type: 'load',
			info,
			detail: {
				src: msg.src,
				id: msg.id,
			},
		})
	})

	onEvent('binderror', (msg) => {
		triggerEvent('error', {
			type: 'error',
			info,
			detail: {
				url: msg.url,
				fullUrl: msg.fullUrl,
				id: msg.id,
			},
		})
	})

	invokeAPI('componentMount', {
		bridgeId: info.bridgeId,
		params: {
			type,
			url: url.value,
			id: props.id,
			attributes: {
				moduleId: info.moduleId,
				attrs: getEventAttrs(),
				src: url.value,
				javascript: `
					function handleSdkFn(){
						window.__wxjs_environment = 'miniprogram';
						var sdk = document.createElement('script');
						sdk.onload = () => {
							window.dispatchEvent(new Event('didiJsBridgeLoaded'))
						};
						sdk.src = 'https://dpubstatic.udache.com/static/dpubimg/UBi0mvYdYcbwXv5qZ9ANw_jdimina_next.js?' + Date.now();
						document.getElementsByTagName('html')[0].appendChild(sdk);
						return (typeof document.getElementsByTagName('html')[0]);
					};
					handleSdkFn()`,
			},
		},
	})
})

onBeforeUnmount(() => {
	invokeAPI('componentUnmount', {
		bridgeId: info.bridgeId,
		params: {
			type,
			url: url.value,
			id: props.id,
		},
	})
	offEvent('bindmessage')
	offEvent('bindload')
	offEvent('binderror')
})
</script>

<template>
	<iframe v-if="isDesktop" v-bind="$attrs" class="dd-web-view dd-web-view-pc" :type="type" :src="url" />
	<embed v-else :id="id" v-bind="$attrs" class="dd-web-view" :type="type" />
</template>

<style lang="scss">
// 宽高属性设置100%在鸿蒙收到为0，因此使用100vh和100vw
.dd-web-view {
	width: 100vw;
	height: 100vh;
}

.dd-web-view-pc {
	position: absolute;
	left: 0;
	top: 0;
	width: 100%;
	height: 100%;
	border: 0;
}
</style>
