<script setup>
// 单项选择器，内部由多个 radio 组成。
// https://developers.weixin.qq.com/miniprogram/dev/component/radio-group.html

import { triggerEvent, useInfo } from '@/common/events'

const props = defineProps({
	/**
	 * id，为 label 使用
	 */
	id: {
		type: String,
	},
	/**
	 * name，为表单使用
	 */
	name: {
		type: String,
	},
})

// 注入表单组件提供的方法
const collectFormValue = inject('collectFormValue', undefined)
const selected = ref(null)

function selectValue(value) {
	selected.value = value
	collectFormValue?.(props.name, selected.value)
}

const info = useInfo()
function handleValueChange(event) {
	collectFormValue?.(props.name, selected.value)
	triggerEvent('change', {
		event,
		info,
		detail: {
			value: selected.value,
		},
	})
}

provide('selected', selected)
provide('selectValue', selectValue)
provide('handleValueChange', handleValueChange)
</script>

<template>
	<div :id="id" v-bind="$attrs" class="dd-radio-group">
		<slot />
	</div>
</template>

<style lang="scss">
.dd-radio-group {
	display: block;

	&[hidden] {
		display: none;
	}
}
</style>
