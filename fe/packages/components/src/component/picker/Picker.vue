<script setup>
// 从底部弹起的滚动选择器
// https://developers.weixin.qq.com/miniprogram/dev/component/picker.html

defineProps({
	/**
	 * 选择器的标题，仅安卓可用
	 */
	headerText: {
		type: String,
	},
	/**
	 * 选择器类型
	 */
	mode: {
		type: String,
		default: 'selector',
		validator: (value) => {
			return ['selector', 'multiSelector', 'time', 'date', 'region'].includes(value)
		},
	},
	/**
	 * 是否禁用
	 */
	disabled: {
		type: Boolean,
		default: false,
	},
	// 普通选择器：mode = selector, 多列选择器：mode = multiSelector
	/**
	 * mode 为 selector 或 multiSelector 时，range 有效
	 */
	range: {
		type: [Array, Object],
		default: () => [],
	},
	/**
	 * 当 range 是一个 Object Array 时，通过 range-key 来指定 Object 中 key 的值作为选择器显示内容
	 */
	rangeKey: {
		type: String,
	},
	// 时间选择器：mode = time, 日期选择器：mode = date
	/**
	 * 表示有效时间范围的开始，字符串格式为"hh:mm"
	 * 表示有效日期范围的开始，字符串格式为"YYYY-MM-DD"
	 */
	start: {
		type: String,
	},
	/**
	 * 表示有效时间范围的结束，字符串格式为"hh:mm"
	 * 表示有效日期范围的结束，字符串格式为"YYYY-MM-DD"
	 */
	end: {
		type: String,
	},
	/**
	 * 有效值 year,month,day，表示选择器的粒度
	 */
	fields: {
		type: String,
		default: 'day',
		validator: (value) => {
			return ['year', 'month', 'day'].includes(value)
		},
	},
	// 省市区选择器：mode = region
	customItem: {
		type: String,
	},
	/**
	 * 选择器层级
	 */
	level: {
		type: String,
		default: 'region',
		validator: (value) => {
			return ['province', 'city', 'region', 'sub-district'].includes(value)
		},
	},
	/**
	 * 表示选择了 range 中的第几个（下标从 0 开始）
	 */
	value: {
		type: [Number, String, Array],
		default: (props) => {
			switch (props.mode) {
				case 'selector':
					return 0
				case 'multiSelector':
					return []
				case 'time': {
					const now = new Date()
					const hours = String(now.getHours()).padStart(2, '0')
					const minutes = String(now.getMinutes()).padStart(2, '0')
					return `${hours}:${minutes}`
				}
				case 'date': {
					const now = new Date()
					const year = now.getFullYear()
					const month = String(now.getMonth() + 1).padStart(2, '0') // 月份是从0开始的，所以需要加1
					const day = String(now.getDate()).padStart(2, '0') // getDate()返回的是1-31的数字
					return `${year}-${month}-${day}`
				}
			}
		},
	},
})

// TODO: showPickerView
</script>

<template>
	<div v-bind="$attrs" class="dd-picker">
		<slot />
	</div>
</template>

<style lang="scss">
.dd-picker {
	display: block;

	&[hidden] {
		display: none;
	}
}
</style>
