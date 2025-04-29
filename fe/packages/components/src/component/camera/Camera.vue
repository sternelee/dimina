<script setup>
// 系统相机
// https://developers.weixin.qq.com/miniprogram/dev/component/camera.html
import { isAndroid, isDesktop, isHarmonyOS, isIOS } from '@dimina/common'
import { useInfo } from '@/common/events'

const props = defineProps({
	/**
	 * 应用模式，只在初始化时有效，不能动态变更
	 * 合法值 normal, scanCode
	 */
	mode: {
		type: String,
		default: 'normal',
		validator: (value) => {
			return ['normal', 'scanCode'].includes(value)
		},
	},
	/**
	 * 分辨率，不支持动态修改
	 * 合法值 low medium high
	 */
	resolution: {
		type: String,
		default: 'medium',
		validator: (value) => {
			return ['low', 'medium', 'high'].includes(value)
		},
	},
	/**
	 * 摄像头朝向
	 * 合法值 front back
	 */
	devicePosition: {
		type: String,
		default: 'back',
		validator: (value) => {
			return ['front', 'back'].includes(value)
		},
	},
	/**
	 * 闪光灯
	 * 合法值 auto, on, off, torch
	 */
	flash: {
		type: String,
		default: 'auto',
		validator: (value) => {
			return ['auto', 'on', 'off', 'torch'].includes(value)
		},
	},
	/**
	 * 指定期望的相机帧数据尺寸
	 * 合法值 small medium large
	 */
	frameSize: {
		type: String,
		default: 'medium',
		validator: (value) => {
			return ['small', 'medium', 'large'].includes(value)
		},
	},
})

useInfo()
const type = 'native/camera'

watch([() => props.devicePosition, () => props.devicePosition, () => props.flash, () => props.frameSize], ([newDevicePosition, newFlash, newFrameSize], [oldDevicePosition, oldFlash, oldFrameSize]) => {

})

onMounted(() => {

})

onBeforeUnmount(() => {

})
</script>

<template>
	<div v-if="isDesktop" v-bind="$attrs" class="dd-camera dd-camera-desktop">
		未找到摄像头
	</div>
	<div v-else-if="isIOS" v-bind="$attrs" class="dd-camera">
		<!-- iOS 特定的内容 -->
		<div class="dd-camera-container">
			<div style="width: 101%;height: 101%;" />
		</div>
	</div>
	<!-- Android 特定的内容 -->
	<embed v-else-if="isAndroid" v-bind="$attrs" class="dd-camera" type="application/view" :comp_type="type" />
	<!-- HarmonyOS 特定的内容 -->
	<embed v-else-if="isHarmonyOS" v-bind="$attrs" class="dd-camera" :type="type" />
</template>

<style lang="scss">
.dd-camera {
	width: inherit;
	height: inherit;

	&[hidden] {
		display: none;
	}

	.dd-camera-container {
		overflow: scroll;
		-webkit-overflow-scrolling: touch;
		width: 100%;
		height: 100%;
	}
}

.dd-camera-desktop {
	color: white;
	background-color: gray;
	display: flex;
    align-items: center;
}
</style>
