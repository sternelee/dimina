<script setup>
// https://developers.weixin.qq.com/miniprogram/dev/component/image.html
import { hasEvent, triggerEvent, useInfo } from '@/common/events'
import { useTapEvents } from '@/common/useTapEvents'
import { useTouchEvents } from '@/common/useTouchEvents'

const props = defineProps({
	src: {
		type: String,
		default: '',
	},
	lazyLoad: {
		type: Boolean,
		default: false,
	},
	lazyLoadMargin: {
		type: Number,
		default: 2,
	},
	webp: {
		type: Boolean,
		default: false,
	},
	showMenuByLongpress: {
		type: Boolean,
		default: false,
	},
	referrerPolicy: {
		type: String,
		default: 'unsafe-url',
	},
	mode: {
		type: String,
		default: 'scaleToFill',
		validator: (val) => {
			return ['scaleToFill', 'aspectFit', 'aspectFill', 'widthFix', 'heightFix', 'top', 'bottom', 'center', 'left', 'right', 'top left', 'top right', 'bottom left', 'bottom right'].includes(val)
		},
	},
})

const MODE_CLASS_MAP = {
	'scaleToFill': 'dd-image-scale',
	'aspectFit': 'dd-image-aspect',
	'aspectFill': 'dd-image-fill',
	'widthFix': 'dd-image-width',
	'heightFix': 'dd-image-height',
	'top': 'dd-image-top',
	'bottom': 'dd-image-bottom',
	'center': 'dd-image-center',
	'left': 'dd-image-left',
	'right': 'dd-image-right',
	'top left': 'dd-image-top-left',
	'top right': 'dd-image-top-right',
	'bottom left': 'dd-image-bottom-left',
	'bottom right': 'dd-image-bottom-right',
}

const dynamicClass = computed(() => MODE_CLASS_MAP[props.mode] || '')

const imgRef = ref(null)
const conRef = ref(null)
const renderedSrc = ref(props.lazyLoad ? '' : props.src)
let intersectionObserver

const info = useInfo()
let lastCompletedSrc = ''

onMounted(() => {
	if (props.mode === 'widthFix') {
		conRef.value.style.height = 'auto'
	}
	else if (props.mode === 'heightFix') {
		conRef.value.style.width = 'auto'
	}
	if (props.lazyLoad && 'IntersectionObserver' in window) {
		const margin = Math.max(Number(props.lazyLoadMargin) || 0, 0)
		intersectionObserver = new IntersectionObserver((entries) => {
			if (entries.some(entry => entry.isIntersecting || entry.intersectionRatio > 0)) {
				renderedSrc.value = props.src
				intersectionObserver.disconnect()
				intersectionObserver = undefined
			}
		}, { rootMargin: `${margin * 100}vh ${margin * 100}vw` })
		intersectionObserver.observe(conRef.value)
	}
	else {
		renderedSrc.value = props.src
	}
	checkCompletedImage()
})

onBeforeUnmount(() => intersectionObserver?.disconnect())

watch(
	() => props.src,
	async () => {
		lastCompletedSrc = ''
		if (!props.lazyLoad || !intersectionObserver) renderedSrc.value = props.src
		await nextTick()
		checkCompletedImage()
	},
)

function handleLoaded(event) {
	lastCompletedSrc = props.src
	triggerEvent('load', {
		event,
		info,
		detail: {
			width: imgRef.value?.width,
			height: imgRef.value?.height,
		},
	})
}

function checkCompletedImage() {
	const img = imgRef.value
	if (!img || !props.src || !img.complete || img.naturalWidth <= 0 || lastCompletedSrc === props.src) {
		return
	}

	handleLoaded(new Event('load'))
}

function handleError(event) {
	triggerEvent('error', {
		event,
		info,
		detail: {
			errMsg: props.src,
		},
	})
}

function handleContextMenu(event) {
	if (!props.showMenuByLongpress) event.preventDefault()
}

// 判断是否有tap事件属性
const hasTapEvent = hasEvent(info, 'tap')
if (hasTapEvent) {
	useTapEvents(conRef, (event) => {
		if (!props.disabled) {
			if (props.hoverStopPropagation) {
				event.stopPropagation()
			}
			triggerEvent('tap', { event, info })
		}
	})
}

// 判断是否有触摸相关事件属性
const hasTouchEvents = hasEvent(info, 'touchstart') || hasEvent(info, 'touchmove')
	|| hasEvent(info, 'touchend') || hasEvent(info, 'touchcancel')
	|| hasEvent(info, 'longpress') || hasEvent(info, 'longtap')

// 只有当存在触摸相关事件属性时，才使用触摸事件处理逻辑
if (hasTouchEvents) {
	useTouchEvents(info, conRef)
}
</script>

<template>
	<span ref="conRef" v-bind="$attrs" class="dd-image" @contextmenu="handleContextMenu">
		<img
			ref="imgRef" :class="dynamicClass" :src="renderedSrc" alt="" decoding="async"
			:loading="props.lazyLoad ? 'lazy' : 'eager'" :referrerpolicy="referrerPolicy" @load="handleLoaded"
			@error="handleError"
		/>
	</span>
</template>

<style lang="scss">
.dd-image {
	display: inline-block;
	width: inherit;
	height: inherit;
	overflow: hidden;
	img {
		width: inherit;
		height: inherit;
		pointer-events: none; // 不会响应点击事件，事件将直接传递到 span 元素，防止 target/currentTarget 为 img 元素
		&[src=''],
		&:not([src]) {
			opacity: 0; /* 隐藏没有src或src为空的图片 */
		}
	}

	&[hidden] {
		display: none;
	}
}

.dd-image-scale {
	width: 100%;
	height: 100%;
	object-fit: fill;
}

.dd-image-aspect {
	width: 100%;
	height: 100%;
	object-fit: contain;
}

.dd-image-fill {
	width: 100%;
	height: 100%;
	object-fit: cover;
}

.dd-image-width {
	width: 100%;
	height: auto;
}

.dd-image-height {
	width: auto;
	height: 100%;
}

.dd-image-top {
	width: 100%;
	height: 100%;
	object-fit: none;
	object-position: top;
}

.dd-image-bottom {
	width: 100%;
	height: 100%;
	object-fit: none;
	object-position: bottom;
}

.dd-image-center {
	width: 100%;
	height: 100%;
	object-fit: none;
	object-position: center;
}

.dd-image-left {
	width: 100%;
	height: 100%;
	object-fit: none;
	object-position: left;
}

.dd-image-right {
	width: 100%;
	height: 100%;
	object-fit: none;
	object-position: right;
}

.dd-image-top-left {
	width: 100%;
	height: 100%;
	object-fit: none;
	object-position: top left;
}

.dd-image-top-right {
	width: 100%;
	height: 100%;
	object-fit: none;
	object-position: top right;
}

.dd-image-bottom-left {
	width: 100%;
	height: 100%;
	object-fit: none;
	object-position: bottom left;
}

.dd-image-bottom-right {
	width: 100%;
	height: 100%;
	object-fit: none;
	object-position: bottom right;
}
</style>
