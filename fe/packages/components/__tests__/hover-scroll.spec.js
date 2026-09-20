/** @vitest-environment jsdom */
import { createApp, h, nextTick, provide } from 'vue'
import Button from '../src/component/button/Button.vue'
import View from '../src/component/view/View.vue'
import Navigator from '../src/component/navigator/Navigator.vue'

let app, host
beforeEach(() => {
	vi.useFakeTimers()
	window.__message = { invoke: vi.fn(), off: vi.fn(), on: vi.fn(), send: vi.fn() }
	window.__callback = { remove: vi.fn(), store: vi.fn() }
})
afterEach(() => {
	app?.unmount()
	host?.remove()
	vi.useRealTimers()
})
function mount(component) {
	host = document.createElement('div')
	document.body.appendChild(host)
	app = createApp({
		setup() {
			provide('bridgeId', 'bridge-1')
			provide('path', 'page-path')
			provide('page-path', { id: 'module-1' })
			return () => h(component, { url: '/pages/next', hoverClass: 'pressed', hoverStartTime: 20, hoverStayTime: 70 })
		},
	})
	app.mount(host)
	return host.firstElementChild
}
function touch(element, type, x = 0, y = 0) {
	const point = { identifier: 1, clientX: x, clientY: y, pageX: x, pageY: y }
	const event = new Event(type, { bubbles: true })
	Object.assign(event, { touches: type === 'touchend' ? [] : [point], changedTouches: [point] })
	element.dispatchEvent(event)
}
async function advance(ms) {
	vi.advanceTimersByTime(ms)
	await nextTick()
}
for (const [name, component] of Object.entries({ Button, View, Navigator })) {
	describe(`${name} scroll feedback`, () => {
		it('does not enter pressed state after a scroll gesture starts', async () => {
			const element = mount(component)
			touch(element, 'touchstart')
			touch(element, 'touchmove', 0, 30)
			await advance(20)
			expect(element.classList.contains('pressed')).toBe(false)
			touch(element, 'touchend', 0, 30)
			await advance(100)
			expect(element.classList.contains('pressed')).toBe(false)
		})
		it('immediately clears active feedback on horizontal movement', async () => {
			const element = mount(component)
			touch(element, 'touchstart')
			await advance(20)
			expect(element.classList.contains('pressed')).toBe(true)
			touch(element, 'touchmove', 30, 0)
			await nextTick()
			expect(element.classList.contains('pressed')).toBe(false)
		})
		it('clears feedback when its ancestor actually scrolls', async () => {
			const element = mount(component)
			touch(element, 'touchstart')
			await advance(20)
			host.dispatchEvent(new Event('scroll'))
			await nextTick()
			expect(element.classList.contains('pressed')).toBe(false)
		})
		it('cancels pending feedback on document scroll and can be pressed again', async () => {
			const element = mount(component)
			touch(element, 'touchstart')
			document.dispatchEvent(new Event('scroll'))
			await advance(100)
			expect(element.classList.contains('pressed')).toBe(false)
			touch(element, 'touchstart')
			await advance(20)
			expect(element.classList.contains('pressed')).toBe(true)
		})
		it('checks the endpoint even when touchmove is missing', async () => {
			const element = mount(component)
			touch(element, 'touchstart')
			touch(element, 'touchend', 0, 30)
			await advance(100)
			expect(element.classList.contains('pressed')).toBe(false)
		})
		it('does not cancel for an unrelated scrolling element', async () => {
			const element = mount(component)
			const unrelated = document.createElement('div')
			host.appendChild(unrelated)
			touch(element, 'touchstart')
			unrelated.dispatchEvent(new Event('scroll'))
			await advance(20)
			expect(element.classList.contains('pressed')).toBe(true)
		})
		it('ignores a touch within 50ms of an ancestor scroll, but accepts one at 50ms', async () => {
			const element = mount(component)
			host.dispatchEvent(new Event('scroll'))
			await advance(49)
			touch(element, 'touchstart')
			await advance(20)
			expect(element.classList.contains('pressed')).toBe(false)
			touch(element, 'touchend')
			host.dispatchEvent(new Event('scroll'))
			await advance(50)
			touch(element, 'touchstart')
			await advance(20)
			expect(element.classList.contains('pressed')).toBe(true)
		})
		it('ignores touches during continued document scrolling', async () => {
			const element = mount(component)
			document.dispatchEvent(new Event('scroll'))
			await advance(40)
			document.dispatchEvent(new Event('scroll'))
			await advance(40)
			touch(element, 'touchstart')
			await advance(100)
			expect(element.classList.contains('pressed')).toBe(false)
		})
		it('does not suppress a new touch after an unrelated scroll', async () => {
			const element = mount(component)
			const unrelated = document.createElement('div')
			host.appendChild(unrelated)
			unrelated.dispatchEvent(new Event('scroll'))
			touch(element, 'touchstart')
			await advance(20)
			expect(element.classList.contains('pressed')).toBe(true)
		})
		it('cancels feedback at the 10px movement boundary', async () => {
			const element = mount(component)
			touch(element, 'touchstart')
			touch(element, 'touchmove', 10, 0)
			await advance(20)
			expect(element.classList.contains('pressed')).toBe(false)
		})
		it('preserves slight touch jitter and tap feedback timing', async () => {
			const element = mount(component)
			touch(element, 'touchstart')
			touch(element, 'touchmove', 2, 2)
			touch(element, 'touchend', 2, 2)
			await advance(20)
			expect(element.classList.contains('pressed')).toBe(true)
			await advance(70)
			expect(element.classList.contains('pressed')).toBe(false)
		})
	})
}
