<script setup>
// 滑块视图容器。其中只可放置swiper-item组件，否则会导致未定义的行为。
// https://developers.weixin.qq.com/miniprogram/dev/component/swiper.html

import { triggerEvent, useInfo } from '@/common/events'

const props = defineProps({
	/**
	 * 是否显示面板指示点
	 */
	indicatorDots: {
		type: Boolean,
		default: false,
	},
	/**
	 * 指示点颜色
	 */
	indicatorColor: {
		type: String,
		default: 'rgba(0, 0, 0, .3)',
	},
	/**
	 * 当前选中的指示点颜色
	 */
	indicatorActiveColor: {
		type: String,
		default: '#000000',
	},
	/**
	 * 是否自动切换
	 */
	autoplay: {
		type: Boolean,
		default: false,
	},
	/**
	 * 当前所在滑块的 index
	 */
	current: {
		type: Number,
		default: 0,
	},
	/**
	 * 自动切换时间间隔
	 */
	interval: {
		type: Number,
		default: 5000,
	},
	/**
	 * 滑动动画时长
	 */
	duration: {
		type: Number,
		default: 500,
	},
	/**
	 * 是否衔接滑动(循环滚动)
	 */
	circular: {
		type: Boolean,
		default: false,
	},
	/**
	 * 滑动方向是否为纵向
	 */
	vertical: {
		type: Boolean,
		default: false,
	},
	/**
	 * 同时显示的滑块数量
	 */
	displayMultipleItems: {
		type: Number,
		default: 1,
	},
	/**
	 * 前边距，可用于露出前一项的一小部分，接受 px 和 rpx 值
	 */
	previousMargin: {
		type: String,
		default: '0px',
	},
	/**
	 * 指定 swiper 切换缓动动画类型
	 * default	默认缓动函数
	 * linear	线性动画
	 * easeInCubic	缓入动画
	 * easeOutCubic	缓出动画
	 * easeInOutCubic	缓入缓出动画
	 */
	easingFunction: {
		type: String,
		default: 'default',
		validator: (value) => {
			return ['default', 'linear', 'easeInCubic', 'easeOutCubic', 'easeInOutCubic'].includes(value)
		},
	},
	/**
	 * 后边距，可用于露出后一项的一小部分，接受 px 和 rpx 值
	 */
	nextMargin: {
		type: String,
		default: '0px',
	},
	/**
	 * 当 swiper-item 的个数大于等于 2，关闭 circular 并且开启 previous-margin 或 next-margin 的时候，可以指定这个边距是否应用到第一个、最后一个元素
	 */
	snapToEdge: {
		type: Boolean,
		default: false,
	},
})

const info = useInfo()

const slots = useSlots()
const slotCount = ref(0)
const clonedItems = ref([])
const realSlotCount = ref(0)

// 添加标记来追踪内部变更
let isInternalChange = false

// 递归查找所有子节点中是 Swiper-Item 的节点数量
function findSwiperItems(nodes) {
	const res = []
	for (let i = 0; i < nodes.length; i++) {
		const vnode = nodes[i]
		if (vnode.type?.__name === 'SwiperItem') {
			res.push(vnode)
		}
		else if (vnode.children) {
			// 如果当前节点有子节点，则递归查找
			res.push(...findSwiperItems(vnode.children.default ? vnode.children.default() : vnode.children))
		}
	}

	return res
}

// 监听插槽内容变化
watchEffect(() => {
	// 获取插槽中子节点的数量作为指示点数量
	if (slots.default) {
		const slotElements = slots.default()
		const res = findSwiperItems(slotElements)

		slotCount.value = res.length

		if (props.circular && res.length > 1) {
			clonedItems.value = [
				res[res.length - 1], // 克隆最后一个元素到最前面
				res[0], // 克隆第一个元素到最后面
			]
			realSlotCount.value = slotCount.value + 2
		}
		else {
			clonedItems.value = []
			realSlotCount.value = slotCount.value
		}
	}
	else {
		slotCount.value = 0
		realSlotCount.value = 0
	}
})

const currentIndex = ref(props.current)

const swiperSliders = ref(null)
const swiperFrame = ref(null)

let startX = 0
let startY = 0
let isDragging = false
let containerRect = { width: 0, height: 0 }
let moveX = 0
let moveY = 0
let startTime = 0
let lastPositionX = 0
let lastPositionY = 0
let rafId
let source = ''

const wrapperStyle = ref({
	transform: props.vertical ? `translateY(-${props.current}00%)` : `translateX(-${props.current}00%)`,
	transition: `transform ${props.duration}ms ease`,
	flexDirection: props.vertical ? 'column' : 'row',
})

const easingParsed = computed(() => {
	switch (props.easingFunction) {
		case 'linear':
			return 'linear'
		case 'easeInCubic':
			return 'ease-in'
		case 'easeOutCubic':
			return 'ease-out'
		case 'easeInOutCubic':
			return 'ease-in-out'
		default:
			return 'ease-in'
	}
})

// 计算滑动速度和方向
function getVelocity(distance, time) {
	return Math.abs(distance) / Math.max(time, 16) // 最小 16ms (60fps)
}

// 方向检测函数
function checkDirection(deltaX, deltaY, event) {
	const absDeltaX = Math.abs(deltaX)
	const absDeltaY = Math.abs(deltaY)

	// 组件是垂直组件
	if (props.vertical) {
		// 在垂直方向滑动距离大于水平方向时才处理为组件滑动
		isDragging = absDeltaX < absDeltaY
		if (isDragging && absDeltaY > absDeltaX) {
			// 用户垂直方向滑动距离大于水平方向，用户在组件内滑动且方向与组件滑动方向一致,阻止页面默认滚动行为
			event.preventDefault()
		}
	}
	else {
		// 组件是水平组件，在水平方向滑动距离大于垂直方向时才处理为组件滑动
		isDragging = absDeltaX > absDeltaY
		if (isDragging && absDeltaX > absDeltaY) {
			// 用户水平方向滑动距离大于垂直方向，用户在组件内滑动且方向与组件滑动方向一致,阻止页面默认滚动行为
			event.preventDefault()
		}
	}
}

function requestMargin() {
	if (props.vertical) {
		swiperSliders.value.style.left = 0
		swiperSliders.value.style.right = 0
		swiperSliders.value.style.top = props.previousMargin
		swiperSliders.value.style.bottom = props.nextMargin
		swiperFrame.value.style.width = '100%'
		swiperFrame.value.style.height = `${Math.abs(100 / props.displayMultipleItems)}%`
	}
	else {
		swiperSliders.value.style.left = props.previousMargin
		swiperSliders.value.style.right = props.nextMargin
		swiperSliders.value.style.top = 0
		swiperSliders.value.style.bottom = 0
		swiperFrame.value.style.height = '100%'
		swiperFrame.value.style.width = `${Math.abs(100 / props.displayMultipleItems)}%`
	}
}

function setNewCurrent(newCurrent) {
	if (newCurrent === currentIndex.value) {
		return
	}

	currentIndex.value = newCurrent
	updateTransform()

	const maxLength = clonedItems.value.length ? realSlotCount.value - 2 : realSlotCount.value

	triggerEvent('change', {
		info,
		detail: {
			current: (newCurrent + maxLength) % maxLength,
			source,
		},
	})
}

watch(
	[() => props.vertical, () => props.autoplay, () => props.current, () => props.previousMargin, () => props.nextMargin, () => props.circular],
	([newVertical, newAutoplay, newCurrent, newPreviousMargin, newNextMargin, newCircular], [oldVertical, oldAutoplay, _oldCurrent, oldPreviousMargin, oldNextMargin, oldCircular]) => {
		if (oldVertical !== newVertical) {
			wrapperStyle.value.flexDirection = newVertical ? 'column' : 'row'
			updateTransform()
			wrapperStyle.value.transition = 'none'
		}
		if (oldAutoplay !== newAutoplay) {
			if (newAutoplay) {
				startAutoplay()
			}
			else {
				stopAutoplay()
			}
		}

		// 只有在不是内部变更时才响应current的变化
		if (newCurrent !== currentIndex.value && !isInternalChange) {
			source = ''
			setNewCurrent(newCurrent)
		}

		if (oldPreviousMargin !== newPreviousMargin || newNextMargin !== oldNextMargin) {
			requestMargin()
		}

		if (oldCircular !== newCircular) {
			if (clonedItems.value.length) {
				let newCurrent = currentIndex.value + 1
				if (newCurrent >= slotCount.value) {
					newCurrent = 1
				}
				if (props.vertical) {
					wrapperStyle.value.transform = `translateY(-${newCurrent}00%)`
				}
				else {
					wrapperStyle.value.transform = `translateX(-${newCurrent}00%)`
				}
				wrapperStyle.value.transition = 'none'
			}
			else {
				let newCurrent = currentIndex.value - 1
				if (newCurrent < 0) {
					newCurrent = 0
				}
				if (props.vertical) {
					wrapperStyle.value.transform = `translateY(${newCurrent}00%)`
				}
				else {
					wrapperStyle.value.transform = `translateX(${newCurrent}00%)`
				}
				wrapperStyle.value.transition = 'none'
			}
		}
	},
)

function startDrag(event) {
	// 拖动时，禁止自动播放
	stopAutoplay()

	// 立即中断当前动画
	if (rafId) {
		cancelAnimationFrame(rafId)
		rafId = undefined
	}

	// 重置transition以立即响应
	wrapperStyle.value.transition = 'none'

	startTime = Date.now()
	isDragging = false // 重置为 false，等待 checkDirection 判断
	startX = event.touches ? event.touches[0].clientX : event.clientX
	startY = event.touches ? event.touches[0].clientY : event.clientY
	moveX = 0
	moveY = 0
	containerRect = {
		width: swiperFrame.value.offsetWidth,
		height: swiperFrame.value.offsetHeight,
	}
	const rect = swiperFrame.value.getBoundingClientRect()
	lastPositionX = rect.x
	lastPositionY = rect.y
}

function drag(event) {
	moveX = (event.touches ? event.touches[0].clientX : event.clientX) - startX
	moveY = (event.touches ? event.touches[0].clientY : event.clientY) - startY

	// 检查滑动方向
	checkDirection(moveX, moveY, event)

	if (!isDragging) {
		return
	}

	let move = props.vertical ? moveY : moveX
	const containerSize = props.vertical ? containerRect.height : containerRect.width

	// 计算当前移动距离相对于容器尺寸的比例
	const moveRatio = move / containerSize

	if (props.circular) {
		const isAtStart = currentIndex.value === 0
		const isAtEnd = currentIndex.value === (clonedItems.value.length ? realSlotCount.value - 3 : realSlotCount.value - 1)

		// 优化阻尼效果：使用非线性函数，随着拖动距离增加，阻力逐渐增大
		if ((isAtStart && move > 0) || (isAtEnd && move < 0)) {
			// 计算阻尼因子，使用0.5 - 0.25 / (moveRatio + 0.5)非线性函数
			const dampingFactor = Math.abs(moveRatio)
			if (isAtStart && move > 0) {
				move = move * (0.5 - 0.25 / (dampingFactor + 0.5))
			}
			else if (isAtEnd && move < 0) {
				move = move * (0.5 - 0.25 / (dampingFactor + 0.5))
			}
		}
	}

	if (props.vertical) {
		const translateY = 100 * ((move / containerRect.height) - (currentIndex.value + (clonedItems.value.length ? 1 : 0)))
		wrapperStyle.value.transform = `translateY(${translateY}%)`
	}
	else {
		const translateX = 100 * ((move / containerRect.width) - (currentIndex.value + (clonedItems.value.length ? 1 : 0)))
		wrapperStyle.value.transform = `translateX(${translateX}%)`
	}

	if (rafId) {
		cancelAnimationFrame(rafId)
		rafId = undefined
	}
}

function endDrag() {
	if (!isDragging) {
		wrapperStyle.value.transform = props.vertical
			? `translateY(-${currentIndex.value}00%)`
			: `translateX(-${currentIndex.value}00%)`
		return
	}

	const elapsedTime = Date.now() - startTime
	startAutoplay()

	if (rafId) {
		cancelAnimationFrame(rafId)
		rafId = undefined
	}

	const move = props.vertical ? moveY : moveX

	if (move === 0) {
		isDragging = false
		startAutoplay()
		return
	}

	const velocity = getVelocity(move, elapsedTime)

	// 定义速度阈值为 0.2
	const VELOCITY_THRESHOLD = 0.2

	const fallback = () => {
		// 确保过渡动画已设置，使用更平滑的缓动效果
		const isAtEdge = currentIndex.value === 0 || currentIndex.value === (slotCount.value - 1)
		const edgeEasing = isAtEdge ? 'cubic-bezier(0.34, 1.56, 0.64, 1)' : easingParsed.value
		wrapperStyle.value.transition = `transform ${props.duration}ms ${edgeEasing}`
		wrapperStyle.value.transform = props.vertical
			? `translateY(-${currentIndex.value}00%)`
			: `translateX(-${currentIndex.value}00%)`
	}

	// 根据速度和距离来判断是否切换到下一张或上一张
	if (slotCount.value > 1) {
		// 如果是手动拖动且速度足够快，直接切换
		if (Math.abs(velocity) > VELOCITY_THRESHOLD) {
			// 根据速度动态调整动画持续时间
			const speedFactor = Math.min(Math.max(Math.abs(velocity), 0.5), 1.5)
			const newDuration = Math.round(props.duration / speedFactor)

			// 设置过渡效果
			wrapperStyle.value.transition = `transform ${newDuration}ms ${easingParsed.value}`

			source = 'touch'
			// 根据方向决定是前进还是后退
			if (move > 0) {
				prevSlide(fallback)
			}
			else {
				nextSlide(fallback)
			}
		}
		else {
			// 回到原位
			fallback()
		}
	}
	else {
		fallback()
	}

	isDragging = false
	startAutoplay()
}

// 切换到下一张
function nextSlide(fallback) {
	const newCurrent = Math.min(currentIndex.value + 1, clonedItems.value.length ? realSlotCount.value - 2 : realSlotCount.value - 1)
	if (newCurrent === currentIndex.value) {
		fallback?.()
		return
	}
	isInternalChange = true
	setNewCurrent(newCurrent)
}

// 切换到上一张
function prevSlide(fallback) {
	const newCurrent = Math.max(currentIndex.value - 1, clonedItems.value.length ? -1 : 0)
	if (newCurrent === currentIndex.value) {
		fallback?.()
		return
	}
	isInternalChange = true
	setNewCurrent(newCurrent)
}

function handleTransitionEnd(event) {
	// 动画结束时重置内部变更标记
	isInternalChange = false

	if (props.circular && slotCount.value > 1) {
		if (currentIndex.value === slotCount.value) {
			currentIndex.value = 0
			wrapperStyle.value.transform = props.vertical ? 'translateY(-100%)' : 'translateX(-100%)'
			wrapperStyle.value.transition = 'none'
		}
		else if (currentIndex.value === -1) {
			currentIndex.value = slotCount.value - 1
			wrapperStyle.value.transform = props.vertical ? `translateY(-${slotCount.value}00%)` : `translateX(-${slotCount.value}00%)`
			wrapperStyle.value.transition = 'none'
		}
	}

	if (rafId) {
		cancelAnimationFrame(rafId)
		rafId = undefined
	}

	triggerEvent('animationfinish', {
		event,
		info,
		detail: {
			current: currentIndex.value,
			source,
		},
	})
}

// 更新容器的transform样式
function updateTransform() {
	let translateValue = currentIndex.value
	if (clonedItems.value.length) {
		translateValue += 1 // 因为我们添加了一个克隆的 slide 在开头
	}

	// 确保之前的动画已被取消
	if (rafId) {
		cancelAnimationFrame(rafId)
		rafId = undefined
	}

	// 重新设置transform和transition
	if (props.vertical) {
		wrapperStyle.value.transform = `translateY(-${translateValue}00%)`
	}
	else {
		wrapperStyle.value.transform = `translateX(-${translateValue}00%)`
	}
	wrapperStyle.value.transition = `transform ${props.duration}ms ${easingParsed.value}`
	// 开始监听动画
	rafId = requestAnimationFrame(monitorAnimation)
}

// 动画过程监听函数
function monitorAnimation() {
	if (rafId) {
		cancelAnimationFrame(rafId)
		rafId = undefined
	}

	const rect = swiperFrame.value.getBoundingClientRect()

	if (props.vertical) {
		const dy = lastPositionY - rect.y
		triggerEvent('transition', {
			info,
			detail: {
				dx: 0,
				dy,
			},
		})
	}
	else {
		const dx = lastPositionX - rect.x
		triggerEvent('transition', {
			info,
			detail: {
				dx,
				dy: 0,
			},
		})
	}

	// FIXME: 持续监听动画过程
	// rafId = requestAnimationFrame(monitorAnimation)
}

let intervalId // 自动播放的定时器ID
// 开始自动播放
function startAutoplay() {
	// 即使启动自动播放开关，数量需要大于1才启动自动播放
	if (props.autoplay && slotCount.value > 1) {
		stopAutoplay()
		intervalId = setInterval(() => {
			if (isDragging) {
				return
			}
			source = 'autoplay'
			nextSlide()
		}, props.interval)
	}
}

// 停止自动播放
function stopAutoplay() {
	if (intervalId) {
		clearInterval(intervalId)
		intervalId = null
	}
}

onMounted(() => {
	requestMargin()
	if (clonedItems.value.length) {
		updateTransform()
		wrapperStyle.value.transition = 'none'
	}
	startAutoplay() // 组件挂载后开始自动播放
})

onBeforeUnmount(() => {
	stopAutoplay() // 组件卸载时停止自动播放
	cancelAnimationFrame(rafId)
	rafId = null
})
</script>

<template>
	<div v-bind="$attrs" class="dd-swiper">
		<div
			class="dd-swiper-wrapper" :aria-label="Boolean(props.vertical) ? '可竖向滚动' : '可横向滚动'" @touchstart="startDrag"
			@touchmove="drag" @touchend="endDrag" @touchcancel="endDrag" @mousedown="startDrag" @mousemove="drag"
			@mouseup="endDrag" @mouseleave="endDrag"
		>
			<div ref="swiperSliders" class="dd-swiper-slides">
				<div
					ref="swiperFrame" class="dd-swiper-slide-frame" :style="wrapperStyle"
					@transitionend="handleTransitionEnd"
				>
					<!-- 插入克隆的最后一个元素 -->
					<template v-if="clonedItems.length">
						<component :is="clonedItems[0]" data-dd-cloned />
					</template>

					<slot />

					<!-- 插入克隆的第一个元素 -->
					<template v-if="clonedItems.length">
						<component :is="clonedItems[1]" data-dd-cloned />
					</template>
				</div>
			</div>
			<div
				v-if="Boolean(props.indicatorDots) && slotCount > 0" class="dd-swiper-dots" :class="{
					'dd-swiper-dots-horizontal': !Boolean(props.vertical),
					'dd-swiper-dots-vertical': Boolean(props.vertical),
				}"
			>
				<div
					v-for="idx in slotCount" :key="idx" :data-dot-index="idx" class="dd-swiper-dot"
					:class="{ 'dd-swiper-dot-active': (idx - 1) === currentIndex }"
				/>
			</div>
		</div>
	</div>
</template>

<style lang="scss">
.dd-swiper {
	display: block;
	height: 150px;

	&[hidden] {
		display: none;
	}

	.dd-swiper-wrapper {
		overflow: hidden;
		position: relative;
		width: 100%;
		height: 100%;
	}

	.dd-swiper-slides {
		position: absolute;
		left: 0;
		top: 0;
		right: 0;
		bottom: 0;
	}

	.dd-swiper-slide-frame {
		display: flex;
		position: absolute;
		left: 0;
		top: 0;
		width: 100%;
		height: 100%;
		will-change: transform;
	}

	.dd-swiper-dots {
		position: absolute;
		font-size: 0;
	}

	.dd-swiper-dots-horizontal {
		left: 50%;
		bottom: 10px;
		text-align: center;
		white-space: nowrap;
		transform: translate(-50%, 0);
	}

	.dd-swiper-dots-horizontal .dd-swiper-dot {
		margin-right: 8px;
	}

	.dd-swiper-dots-horizontal .dd-swiper-dot:last-child {
		margin-right: 0;
	}

	.dd-swiper-dots-vertical {
		right: 10px;
		top: 50%;
		text-align: right;
		transform: translate(0, -50%);
	}

	.dd-swiper-dots-vertical .dd-swiper-dot {
		display: block;
		margin-bottom: 9px;
	}

	.dd-swiper-dots-vertical .dd-swiper-dot:last-child {
		margin-bottom: 0;
	}

	.dd-swiper-dot {
		display: inline-block;
		width: 8px;
		height: 8px;
		transition-property: background-color;
		transition-timing-function: ease;
		background: rgba(0, 0, 0, 0.3);
		border-radius: 50%;
	}

	.dd-swiper-dot-active {
		background-color: #000000;
	}
}
</style>
