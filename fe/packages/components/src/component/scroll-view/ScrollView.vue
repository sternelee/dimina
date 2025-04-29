<script setup>
// 可滚动视图区域。使用竖向滚动时，需要给scroll-view一个固定高度，通过 WXSS 设置 height。组件属性的长度单位默认为px
// https://developers.weixin.qq.com/miniprogram/dev/component/scroll-view.html
import { triggerEvent, useInfo } from '@/common/events'

const props = defineProps({
	/**
	 * 允许横向滚动
	 */
	scrollX: {
		type: Boolean,
		default: false,
	},
	/**
	 * 允许纵向滚动
	 */
	scrollY: {
		type: Boolean,
		default: false,
	},
	/**
	 * 距顶部/左边多远时，触发 scrolltoupper 事件
	 */
	upperThreshold: {
		type: [Number, String],
		default: 50,
	},
	/**
	 * 距底部/右边多远时，触发 scrolltolower 事件
	 */
	lowerThreshold: {
		type: [Number, String],
		default: 50,
	},
	/**
	 * 设置竖向滚动条位置
	 */
	scrollTop: {
		type: [Number, String],
	},
	/**
	 * 设置横向滚动条位置
	 */
	scrollLeft: {
		type: [Number, String],
	},
	/**
	 * 值应为某子元素id（id不能以数字开头）。设置哪个方向可滚动，则在哪个方向滚动到该元素
	 */
	scrollIntoView: {
		type: String,
	},
	/**
	 * 在设置滚动条位置时使用动画过渡
	 */
	scrollWithAnimation: {
		type: Boolean,
		default: false,
	},
	/**
	 * iOS点击顶部状态栏、安卓双击标题栏时，滚动条返回顶部，只支持竖向。自 2.27.3 版本开始，若非显式设置为 false，则在显示尺寸大于屏幕 90% 时自动开启。
	 */
	enableBackToTop: {
		type: Boolean,
		default: false,
	},
	/**
	 * TODO: 开启 passive 特性，能优化一定的滚动性能
	 */
	enablePassive: {
		type: Boolean,
		default: false,
	},
	/**
	 * 开启自定义下拉刷新
	 */
	refresherEnabled: {
		type: Boolean,
		default: false,
	},
	/**
	 * 设置自定义下拉刷新阈值
	 */
	refresherThreshold: {
		type: Number,
		default: 45,
	},
	/**
	 * 设置自定义下拉刷新默认样式，支持设置 black | white | none， none 表示不使用默认样式
	 */
	refresherDefaultStyle: {
		type: String,
		default: 'black',
		validator: (value) => {
			return ['black', 'white', 'none'].includes(value)
		},
	},
	/**
	 * 设置自定义下拉刷新区域背景颜色，默认为透明
	 */
	refresherBackground: {
		type: String,
	},
	/**
	 * 设置当前下拉刷新状态，true 表示下拉刷新已经被触发，false 表示下拉刷新未被触发
	 */
	refresherTriggered: {
		type: Boolean,
		default: false,
	},
	/**
	 * iOS 下 scroll-view 边界弹性控制 (同时开启 enhanced 属性后生效)
	 */
	bounces: {
		type: Boolean,
		default: true,
	},
	/**
	 * 滚动条显隐控制 (同时开启 enhanced 属性后生效)
	 */
	showScrollbar: {
		type: Boolean,
		default: true,
	},
	/**
	 * 滑动减速速率控制, 仅在 iOS 下生效 (同时开启 enhanced 属性后生效)
	 */
	fastDeceleration: {
		type: Boolean,
		default: false,
	},
	/**
	 * 启用 flexbox 布局。开启后，当前节点声明了 display: flex 就会成为 flex container，并作用于其孩子节点
	 */
	enableFlex: {
		type: Boolean,
		default: false,
	},
	/**
	 * 开启 scroll anchoring 特性，即控制滚动位置不随内容变化而抖动，仅在 iOS 下生效，安卓下可参考 CSS overflow-anchor 属性
	 */
	scrollAnchoring: {
		type: Boolean,
		default: false,
	},
	/**
	 * 启用 scroll-view 增强特性，启用后可通过 ScrollViewContext 操作 scroll-view
	 */
	enhanced: {
		type: Boolean,
		default: false,
	},
	/**
	 * 分页滑动效果 (同时开启 enhanced 属性后生效)
	 */
	pagingEnabled: {
		type: Boolean,
		default: false,
	},
	/**
	 * 使 scroll-view 下的 position sticky 特性生效，否则滚动一屏后 sticky 元素会被隐藏
	 */
	usingSticky: {
		type: Boolean,
		default: false,
	},
})

const info = useInfo()
const scrollView = ref(null)

const hideScrollBar = computed(() => {
	if (props.enhanced) {
		return !props.showScrollbar
	}
	return true
})

let lastScrollLeft = 0
let lastScrollTop = 0
let lastScrollToUpperTime = 0
// 滚动事件处理
function handleScroll(event) {
	const el = scrollView.value
	const { scrollTop, scrollLeft, scrollHeight, scrollWidth, clientHeight, clientWidth } = el

	// // 计算滚动的水平距离变化（deltaX）
	const deltaX = scrollLeft - lastScrollLeft
	// // 计算滚动的垂直距离变化（deltaY）
	const deltaY = scrollTop - lastScrollTop

	lastScrollLeft = scrollLeft
	lastScrollTop = scrollTop

	// 滚动事件回调
	triggerEvent('scroll', {
		event,
		info,
		detail: {
			scrollLeft, // 水平滚动的距离
			scrollTop, // // 垂直滚动的距离
			scrollHeight, // 内容总高度
			scrollWidth, // 内容总宽度
			deltaX,
			deltaY,
		},
	})

	if (props.scrollY) {
		// 垂直滚动到顶部
		if (scrollTop <= props.upperThreshold && deltaY < 0 && event.timeStamp - lastScrollToUpperTime > 200) {
			lastScrollToUpperTime = event.timeStamp

			triggerEvent('scrolltoupper', {
				event,
				info,
				detail: {
					direction: 'top',
				},
			})
		}

		// 垂直滚动到底部
		if (scrollTop + clientHeight >= scrollHeight - props.lowerThreshold && deltaY > 0 && event.timeStamp - lastScrollToUpperTime > 200) {
			lastScrollToUpperTime = event.timeStamp

			triggerEvent('scrolltolower', {
				event,
				info,
				detail: {
					direction: 'bottom',
				},
			})
		}
	}

	if (props.scrollX) {
		// 横行滚动到顶部
		if (scrollLeft <= props.upperThreshold && deltaX < 0 && event.timeStamp - lastScrollToUpperTime > 200) {
			lastScrollToUpperTime = event.timeStamp

			triggerEvent('scrolltoupper', {
				event,
				info,
				detail: {
					direction: 'left',
				},
			})
		}

		// 横向滚动到底部
		if (scrollLeft + clientWidth >= scrollWidth - props.lowerThreshold && deltaX > 0 && event.timeStamp - lastScrollToUpperTime > 200) {
			lastScrollToUpperTime = event.timeStamp

			triggerEvent('scrolltolower', {
				event,
				info,
				detail: {
					direction: 'right',
				},
			})
		}
	}
}

// 添加新的事件处理函数
function handleTouchMove(event) {
	if (props.scrollX || props.scrollY) {
		// 触发自定义的 touchmove 事件
		triggerEvent('touchmove', {
			event,
			info,
		})
	}
	else {
		event.preventDefault()
	}
}

// 监听滚动位置的变化
watch(
	() => [props.scrollTop, props.scrollLeft],
	([newScrollTop, newScrollLeft]) => {
		if (scrollView.value) {
			scrollView.value.scrollTo({
				top: newScrollTop,
				left: newScrollLeft,
				behavior: 'instant',
			})
		}
	},
	{ flush: 'post' },
)

onMounted(() => {
	// 初始化滚动位置
	if (scrollView.value) {
		scrollView.value.scrollTop = props.scrollTop
		scrollView.value.scrollLeft = props.scrollLeft
	}
})
</script>

<template>
	<div
		ref="scrollView" v-bind="$attrs" class="dd-scroll-view"
		:class="[{ 'scroll-x': Boolean(props.scrollX), 'scroll-y': Boolean(props.scrollY), 'hide-scrollbar': hideScrollBar }]"
		@scroll="handleScroll"
		@touchmove="handleTouchMove"
	>
		<slot />
	</div>
</template>

<style lang="scss">
.dd-scroll-view {
	position: relative;
	overflow: auto;
	width: 100%;
	height: inherit;
	-webkit-overflow-scrolling: touch;
	max-height: inherit;

	&[hidden] {
		display: none;
	}

	&.scroll-x {
		overflow-x: auto !important;
		overflow-y: hidden !important;
	}

	&.scroll-y {
		overflow-x: hidden !important;
		overflow-y: auto !important;
	}

	// 当两个方向都允许滚动时
	&.scroll-x.scroll-y {
		overflow: auto;
	}

	&.hide-scrollbar {
		scroll-behavior: smooth;
		position: relative;
	}

	&.hide-scrollbar::-webkit-scrollbar {
		width: 0;
		height: 0;
	}

}
</style>
