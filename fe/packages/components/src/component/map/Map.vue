<script setup>
// 地图
// https://developers.weixin.qq.com/miniprogram/dev/component/map.html
import { isAndroid, isDesktop, isHarmonyOS, isIOS } from '@dimina/common'
import { invokeAPI, offEvent, onEvent, triggerEvent, useInfo } from '@/common/events'

const props = defineProps({
	/**
	 * 地图 id
	 */
	id: {
		type: String,
		default: () => `map-${useId()}`,
	},
	/**
	 * 中心经度
	 */
	longitude: {
		type: Number,
		required: true,
	},
	/**
	 * 中心纬度
	 */
	latitude: {
		type: Number,
		required: true,
	},
	/**
	 * 缩放级别，取值范围为3-20
	 */
	scale: {
		type: Number,
		default: 16,
	},
	/**
	 * 最小缩放级别
	 */
	minScale: {
		type: Number,
		default: 3,
	},
	/**
	 * 最大缩放级别
	 */
	maxScale: {
		type: Number,
		default: 20,
	},
	/**
	 * 标记点
	 */
	markers: {
		type: Array,
	},
	/**
	 * 路线
	 */
	polyline: {
		type: Array,
	},
	/**
	 * 圆
	 */
	circles: {
		type: Array,
	},
	/**
	 * 缩放视野以包含所有给定的坐标点
	 */
	includePoints: {
		type: Array,
	},
	/**
	 * 显示带有方向的当前定位点
	 */
	showLocation: {
		type: Boolean,
		default: false,
	},
	/**
	 * 多边形
	 */
	polygons: {
		type: Array,
	},
	/**
	 * 旋转角度，范围 0 ~ 360, 地图正北和设备 y 轴角度的夹角
	 */
	rotate: {
		type: Number,
		default: 0,
	},
	/**
	 * 倾斜角度，范围 0 ~ 40 , 关于 z 轴的倾角
	 */
	skew: {
		type: Number,
		default: 0,
	},
	/**
	 * 展示3D楼块
	 */
	enable3D: {
		type: Boolean,
		default: false,
	},
	/**
	 * 显示指南针
	 */
	showCompass: {
		type: Boolean,
		default: false,
	},
	/**
	 * 显示比例尺
	 */
	showScale: {
		type: Boolean,
		default: false,
	},
	/**
	 * 开启俯视
	 */
	enableOverlooking: {
		type: Boolean,
		default: false,
	},
	/**
	 * 开启最大俯视角，俯视角度从 45 度拓展到 75 度
	 */
	enableAutoMaxOverlooking: {
		type: Boolean,
		default: false,
	},
	/**
	 * 是否支持缩放
	 */
	enableZoom: {
		type: Boolean,
		default: true,
	},
	/**
	 * 是否支持拖动
	 */
	enableScroll: {
		type: Boolean,
		default: true,
	},
	/**
	 * 是否支持旋转
	 */
	enableRotate: {
		type: Boolean,
		default: false,
	},
	/**
	 * 是否开启卫星图
	 */
	enableSatellite: {
		type: Boolean,
		default: false,
	},
	/**
	 * 是否开启实时路况
	 */
	enableTraffic: {
		type: Boolean,
		default: false,
	},
	/**
	 * 是否展示 POI 点
	 */
	enablePOI: {
		type: Boolean,
		default: true,
	},
	/**
	 * 是否展示建筑物
	 */
	enableBuilding: {
		type: Boolean,
	},
})

const info = useInfo()
const type = 'native/map'

watch(
	[
		() => props.longitude,
		() => props.latitude,
		() => props.scale,
		() => props.markers,
		() => props.polyline,
		() => props.polygons,
		() => props.circles,
		() => props.includePoints,
		() => props.showLocation,
	],
	(
		[newLongitude, newLatitude, newScale, newMarkers, newPolyline, newPolygons, newCircles, newIncludePoints, newShowLocation],
		[oldLongitude, oldLatitude, oldScale, oldMarkers, oldPolyline, oldPolygons, oldCircles, oldIncludePoints, oldShowLocation],
	) => {
		const params = { type, id: props.id }

		if (newScale !== oldScale) {
			params.scale = newScale
		}
		if (newMarkers !== oldMarkers) {
			params.markers = newMarkers
		}
		if (newPolyline !== oldPolyline) {
			params.polyline = newPolyline
		}
		if (newPolygons !== oldPolygons) {
			params.polygons = newPolygons
		}
		if (newCircles !== oldCircles) {
			params.circles = newCircles
		}
		if (newIncludePoints !== oldIncludePoints) {
			params.includePoints = newIncludePoints
			params.longitude = newLongitude
			params.latitude = newLatitude
		}
		else {
			if (newLongitude !== oldLongitude || newLatitude !== oldLatitude) {
				params.longitude = newLongitude
				params.latitude = newLatitude
			}
		}
		if (newShowLocation !== oldShowLocation) {
			params.showLocation = newShowLocation
		}

		invokeAPI('propsUpdate', {
			bridgeId: info.bridgeId,
			params,
		})
	},
)

onBeforeMount(() => {
	onEvent('bindcallouttap', (msg) => {
		triggerEvent('callouttap', {
			type: 'callouttap',
			info,
			detail: {
				id: msg.id,
				markerId: msg.markerId,
				longitude: msg.longitude,
				latitude: msg.latitude,
			},
		})
	})

	onEvent('bindmarkertap', (msg) => {
		triggerEvent('markertap', {
			type: 'markertap',
			info,
			detail: {
				id: msg.id,
				markerId: msg.markerId,
				longitude: msg.longitude,
				latitude: msg.latitude,
			},
		})
	})

	onEvent('bindregionchange', (msg) => {
		triggerEvent('regionchange', {
			type: 'regionchange',
			info,
			detail: msg,
		})
	})

	onEvent('bindtap', (msg) => {
		triggerEvent('tap', {
			type: 'tap',
			info,
			detail: {
				markerId: msg.markerId,
			},
		})
	})

	invokeAPI('componentMount', {
		bridgeId: info.bridgeId,
		params: {
			type,
			id: props.id,
			longitude: props.longitude,
			latitude: props.latitude,
			scale: props.scale,
			markers: props.markers,
			polyline: props.polyline,
			polygons: props.polygons,
			circles: props.circles,
			includePoints: props.includePoints,
			showLocation: props.showLocation,
		},
	})
})

onBeforeUnmount(() => {
	invokeAPI('componentUnmount', {
		bridgeId: info.bridgeId,
		params: {
			type,
			id: props.id,
			longitude: props.longitude,
			latitude: props.latitude,
			scale: props.scale,
			markers: props.markers,
			polyline: props.polyline,
			polygons: props.polygons,
			circles: props.circles,
			includePoints: props.includePoints,
			showLocation: props.showLocation,
		},
	})
	offEvent('bindcallouttap')
	offEvent('bindmarkertap')
	offEvent('bindregionchange')
	offEvent('bindtap')
})
</script>

<template>
	<div v-if="isDesktop" v-bind="$attrs" class="dd-map dd-map-desktop">
		未实现组件
	</div>
	<div v-else-if="isIOS" v-bind="$attrs" class="dd-map">
		<!-- iOS 特定的内容 -->
		<div class="dd-map-container">
			<div style="width: 101%; height: 101%" />
		</div>
	</div>
	<!-- Android 特定的内容 -->
	<embed v-else-if="isAndroid" v-bind="$attrs" class="dd-map" type="application/view" :comp_type="type" />
	<!-- HarmonyOS 特定的内容 -->
	<embed v-else-if="isHarmonyOS" :id="id" v-bind="$attrs" class="dd-map" :type="type" />
</template>

<style lang="scss">
.dd-map {
	width: inherit;
	height: inherit;

	&[hidden] {
		display: none;
	}

	.dd-map-container {
		overflow: scroll;
		-webkit-overflow-scrolling: touch;
		width: 100%;
		height: 100%;
	}
}

.dd-map-desktop {
	color: white;
	background-color: gray;
	display: flex;
	align-items: center;
	justify-content: center;
}
</style>
