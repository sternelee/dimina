/** @vitest-environment jsdom */

import { createApp, h, nextTick, provide, reactive } from 'vue'
import Input from '../src/component/input/Input.vue'
import Textarea from '../src/component/textarea/Textarea.vue'

const mounts = []

function mount(component, props) {
	const host = document.createElement('div')
	document.body.appendChild(host)
	const app = createApp({
		setup() {
			provide('bridgeId', 'focus-bridge')
			provide('path', 'focus-page')
			provide('focus-page', { id: 'focus-module' })
			return () => h(component, props)
		},
	})
	app.mount(host)
	mounts.push({ app, host })
	return host.querySelector('input, textarea')
}

beforeEach(() => {
	window.__message = { invoke: vi.fn(), send: vi.fn(), on: vi.fn(), off: vi.fn() }
	window.__callback = { store: vi.fn(), remove: vi.fn() }
})

afterEach(() => {
	for (const { app, host } of mounts.splice(0)) {
		app.unmount()
		host.remove()
	}
	delete window.__message
	delete window.__callback
})

for (const [name, component] of [['input', Input], ['textarea', Textarea]]) {
	describe(`${name} focus 属性`, () => {
		it.each([{ focus: '' }, { focus: true }, { autoFocus: '' }])('挂载时聚焦：%j', (props) => {
			const el = mount(component, props)
			expect(document.activeElement).toBe(el)
		})

		it('未指定 focus 时不聚焦，更新为 true 后聚焦', async () => {
			const props = reactive({ focus: false })
			const el = mount(component, props)
			expect(document.activeElement).not.toBe(el)
			props.focus = true
			await nextTick()
			expect(document.activeElement).toBe(el)
		})

		it('disabled 时不聚焦', () => {
			const el = mount(component, { focus: true, disabled: true })
			expect(document.activeElement).not.toBe(el)
		})
	})
}
