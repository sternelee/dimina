<script setup>
import { hasEvent, triggerEvent, useInfo } from '@/common/events'
import { useTapEvents } from '@/common/useTapEvents'
// 文本
// https://developers.weixin.qq.com/miniprogram/dev/component/text.html

const props = defineProps({
	/**
	 * 文本是否可选，该属性会使文本节点显示为 inline-block
	 */
	userSelect: {
		type: Boolean,
		default: false,
	},
	/**
	 * 显示连续空格
	 * ensp	中文字符空格一半大小
	 * emsp	中文字符空格大小
	 * nbsp	根据字体设置的空格大小
	 */
	space: {
		type: String,
		validator: (value) => {
			return ['ensp', 'emsp', 'nbsp'].includes(value)
		},
	},
	/**
	 * 是否解码
	 * decode可以解析的有 &nbsp; &lt; &gt; &amp; &apos; &ensp; &emsp;
	 */
	decode: {
		type: Boolean,
		default: false,
	},
})

const textRef = ref(null)

function htmlDecode(e) {
	return (
		props.space
		&& (this.space === 'nbsp'
			? (e = e.replace(/ /g, ' '))
			: this.space === 'ensp'
				? (e = e.replace(/ /g, ' '))
				: this.space === 'emsp' && (e = e.replace(/ /g, ' '))),
		props.decode
			? e
					.replace(/&nbsp;/g, ' ')
					.replace(/&ensp;/g, ' ')
					.replace(/&emsp;/g, ' ')
					.replace(/&lt;/g, '<')
					.replace(/&gt;/g, '>')
					.replace(/&quot;/g, '"')
					.replace(/&apos;/g, '\'')
					.replace(/&amp;/g, '&')
			: e
	)
}

onMounted(() => {
	if (textRef.value) {
		const nodes = textRef.value.childNodes
		for (let i = 0; i < nodes.length; i++) {
			const node = nodes[i]
			// 检查节点是否是文本节点
			if (node.nodeType === Node.TEXT_NODE) {
				// 获取文本内容
				const text = node.nodeValue
				// 解码文本内容
				const decodedText = htmlDecode(text)
				const splitText = decodedText.split('\\n')
				// 存在换行符
				if (splitText.length > 1) {
					const newNode = document.createDocumentFragment()
					for (i = 0; i < splitText.length; i++) {
						newNode.appendChild(document.createTextNode(splitText[i]))
						if (i < splitText.length - 1) {
							newNode.appendChild(document.createElement('br'))
						}
					}
					node.parentNode.replaceChild(newNode, node)
				}
				else {
					// 如果解码后的文本不同，则替换原始文本节点
					if (decodedText !== text) {
						// 创建一个新的文本节点
						const newNode = document.createTextNode(decodedText)
						// 替换原始文本节点
						node.parentNode.replaceChild(newNode, node)
					}
				}
			}
		}
	}
})

const info = useInfo()

// 判断是否有tap事件属性
const hasTapEvent = hasEvent(info, 'tap')
if (hasTapEvent) {
	useTapEvents(textRef, (event) => {
		if (!props.disabled) {
			if (props.hoverStopPropagation) {
				event.stopPropagation()
			}
			triggerEvent('tap', { event, info })
		}
	})
}
</script>

<template>
	<span
		ref="textRef" v-bind="$attrs" class="dd-text" :class="{ 'dd-text-selectable': userSelect }"
	>
		<slot />
	</span>
</template>

<style lang="scss">
.dd-text {
	user-select: none;
	display: inline;

	&[hidden] {
		display: none;
	}
}

.dd-text-selectable {
	cursor: auto;
	display: inline-block;
	user-select: text;
}
</style>
