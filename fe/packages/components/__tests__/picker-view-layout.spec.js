/** @vitest-environment jsdom */

import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { createApp, h, nextTick, provide, ref } from 'vue'
import PickerView from '../src/component/picker-view/PickerView.vue'
import PickerViewColumn from '../src/component/picker-view-column/PickerViewColumn.vue'

const PATH = '/pages/index/index'
const ITEM_HEIGHT = 36
const PICKER_HEIGHT = 180

let app
let host
let pickerVisible
let resizeCallbacks

function pickerColumn(size) {
	return h(PickerViewColumn, {}, {
		default: () => Array.from({ length: size }, (_, index) => h('div', {
			style: `height: ${ITEM_HEIGHT}px; line-height: ${ITEM_HEIGHT}px`,
		}, String(index))),
	})
}

function mountPicker(render) {
	host = document.createElement('div')
	document.body.append(host)
	app = createApp({
		setup() {
			provide('bridgeId', 'page-1')
			provide('path', PATH)
			provide(PATH, { id: 'module-1' })
			return render
		},
	})
	app.mount(host)
}

function renderPicker(value) {
	return h(PickerView, {
		'indicator-style': `height: ${ITEM_HEIGHT}px`,
		'value': value,
		'bindchange': 'onChange',
	}, {
		default: () => [pickerColumn(24), pickerColumn(60)],
	})
}

async function flush() {
	await nextTick()
	await nextTick()
}

function contentTransforms() {
	return Array.from(host.querySelectorAll('.dd-picker__content'), node => node.style.transform)
}

beforeEach(() => {
	pickerVisible = false
	resizeCallbacks = []
	window.__message = { send: vi.fn(), invoke: vi.fn(), on: vi.fn(), off: vi.fn() }
	window.__callback = { store: vi.fn(), remove: vi.fn() }
	window.ResizeObserver = class {
		constructor(callback) {
			resizeCallbacks.push(callback)
		}

		observe() {}
		disconnect() {}
	}
	vi.spyOn(HTMLElement.prototype, 'offsetHeight', 'get').mockImplementation(function () {
		if (!pickerVisible) return 0
		if (this.classList.contains('dd-picker-view')) return PICKER_HEIGHT
		if (this.classList.contains('dd-picker__indicator')) return ITEM_HEIGHT
		return 0
	})
})

afterEach(() => {
	app?.unmount()
	host?.remove()
	vi.restoreAllMocks()
	document.body.innerHTML = ''
})

describe('picker-view controlled value and hidden layout', () => {
	it('keeps the latest non-zero controlled value when remounted', async () => {
		const mounted = ref(true)
		const value = ref([8, 17])
		mountPicker(() => mounted.value ? renderPicker(value.value) : null)
		await flush()

		expect(contentTransforms()).toEqual(['translateY(-288px)', 'translateY(-612px)'])
		expect(window.__message.send).not.toHaveBeenCalled()

		mounted.value = false
		await flush()
		value.value = [9, 18]
		mounted.value = true
		await flush()

		expect(contentTransforms()).toEqual(['translateY(-324px)', 'translateY(-648px)'])
		expect(window.__message.send).not.toHaveBeenCalled()
	})

	it('reapplies the centered layout when a hidden picker becomes measurable', async () => {
		mountPicker(() => renderPicker([8, 17]))
		await flush()

		const indicators = host.querySelectorAll('.dd-picker__indicator')
		expect(Array.from(indicators, node => node.style.top)).toEqual(['', ''])

		pickerVisible = true
		resizeCallbacks.at(-1)()
		await flush()

		expect(Array.from(indicators, node => node.style.top)).toEqual(['72px', '72px'])
		expect(Array.from(host.querySelectorAll('.dd-picker__content'), node => node.style.paddingTop)).toEqual(['72px', '72px'])
		expect(contentTransforms()).toEqual(['translateY(-288px)', 'translateY(-612px)'])
		expect(window.__message.send).not.toHaveBeenCalled()
	})
})
