<script setup>
import { isDesktop, sleep } from '@dimina/common'

// 进度条。组件属性的长度单位默认为px
// https://developers.weixin.qq.com/miniprogram/dev/component/progress.html

const props = defineProps({
	/**
	 * 百分比0~100
	 */
	percent: {
		type: [Number, String],
		required: false,
	},
	/**
	 * 在进度条右侧显示百分比
	 */
	showInfo: {
		type: Boolean,
		default: false,
		required: false,
	},
	/**
	 * 圆角大小
	 */
	borderRadius: {
		type: [Number, String],
		default: 0,
		required: false,
	},
	/**
	 * 右侧百分比字体大小
	 */
	fontSize: {
		type: [Number, String],
		default: 16,
		required: false,
	},
	/**
	 * 进度条线的宽度
	 */
	strokeWidth: {
		type: [Number, String],
		default: 6,
		required: false,
	},
	/**
	 * 进度条颜色
	 * @deprecated 请使用activeColor属性
	 */
	color: {
		type: String,
		default: '#09BB07',
		required: false,
	},
	/**
	 * 已选择的进度条的颜色
	 */
	activeColor: {
		type: String,
		default: '#09BB07',
		required: false,
	},
	/**
	 * 未选择的进度条的颜色
	 */
	backgroundColor: {
		type: String,
		default: '#EBEBEB',
		required: false,
	},
	/**
	 * 进度条从左往右的动画
	 */
	active: {
		type: Boolean,
		default: false,
		required: false,
	},
	/**
	 * backwards: 动画从头播；forwards：动画从上次结束点接着播
	 */
	activeMode: {
		type: String,
		default: 'backwards',
		required: false,
	},
	/**
	 * 进度增加1%所需毫秒数
	 */
	duration: {
		type: Number,
		default: 30,
		required: false,
	},
})

const percentParsed = computed(() => {
	return props.active ? 0 : `${props.percent}%`
})

const durationParsed = computed(() => {
	return `${Number(props.duration) * Number(props.percent)}ms`
})

const progressRef = ref(null)

onMounted(async () => {
	if (props.active) {
		if (isDesktop) {
			// 兼容 web 端页面进入动画
			await sleep(540)
		}
		progressRef.value.style.setProperty('--percent', `${props.percent}%`)
	}
})
</script>

<template>
	<div v-bind="$attrs" class="dd-progress">
		<div
			class="dd-progress-bar" aria-label="" :aria-valuenow="`${percent}%`" :style="{
				borderRadius: `${borderRadius}px`,
				backgroundColor,
				height: `${strokeWidth}px`,
			}"
		>
			<div
				ref="progressRef" class="dd-progress-inner-bar"
				:style="{ '--percent': percentParsed, '--duration': durationParsed, 'backgroundColor': activeColor || color }"
			/>
		</div>
		<p class="dd-progress-info" :style="{ fontSize }" :hidden="!showInfo">
			{{ percent }}%
		</p>
	</div>
</template>

<style lang="scss">
.dd-progress {
	display: flex;
	align-items: center;

	&[hidden] {
		display: none;
	}

	.dd-progress-bar {
		flex: 1;
		overflow: hidden;
	}

	.dd-progress-inner-bar {
		--percent: 0;
		--duration: 0ms;
		width: var(--percent);
		height: 100%;
		transition-duration: var(--duration);
		transition-property: width;
	}

	.dd-progress-info {
		margin-top: 0;
		margin-bottom: 0;
		min-width: 2em;
		margin-left: 15px;
		font-size: 16px;
	}
}
</style>
