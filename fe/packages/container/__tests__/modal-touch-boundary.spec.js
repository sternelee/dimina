import fs from 'node:fs'
import { resolve } from 'node:path'
import { afterEach, describe, expect, it, vi } from 'vitest'
import { MiniApp } from '../src/pages/miniApp/miniApp'

function createElement() {
	const listeners = new Map()
	return {
		children: [],
		classList: {
			add: vi.fn(),
			remove: vi.fn(),
		},
		addEventListener: vi.fn((type, listener, options) => {
			listeners.set(type, { listener, options })
		}),
		appendChild(child) {
			this.children.push(child)
			return child
		},
		remove: vi.fn(),
		style: {},
		listeners,
	}
}

afterEach(() => {
	vi.useRealTimers()
	vi.unstubAllGlobals()
})

describe('showModal touch boundary', () => {
	it('prevents touchmove on the modal mask with a non-passive listener', () => {
		vi.stubGlobal('document', { createElement: vi.fn(createElement) })
		const app = Object.create(MiniApp.prototype)
		app.el = createElement()
		app._modalStack = []
		app.createCallbackFunction = vi.fn()

		app._mountModal({})

		const mask = app.el.children[0]
		const touchMove = mask.listeners.get('touchmove')
		const event = {
			cancelable: true,
			preventDefault: vi.fn(),
		}
		touchMove.listener(event)

		expect(touchMove.options).toEqual({ passive: false })
		expect(event.preventDefault).toHaveBeenCalledOnce()
	})

	it('blocks an active iframe touch stream until the last modal closes', () => {
		vi.useFakeTimers()
		vi.stubGlobal('document', { createElement: vi.fn(createElement) })
		const pageListeners = new Map()
		const pageWindow = {
			addEventListener: vi.fn((type, listener, options) => {
				pageListeners.set(type, { listener, options })
			}),
			removeEventListener: vi.fn(),
		}
		const app = Object.create(MiniApp.prototype)
		app.el = createElement()
		app.bridgeList = [{ webview: { iframe: { contentWindow: pageWindow } } }]
		app._modalStack = []
		app._modalPendingTimers = new Set()
		app._modalPageTouchTarget = null
		app._destroyed = false
		app.createCallbackFunction = vi.fn()

		app.showModal({})

		const touchMove = pageListeners.get('touchmove')
		const event = {
			cancelable: true,
			preventDefault: vi.fn(),
			stopImmediatePropagation: vi.fn(),
		}
		touchMove.listener(event)

		expect(touchMove.options).toEqual({ capture: true, passive: false })
		expect(event.preventDefault).toHaveBeenCalledOnce()
		expect(event.stopImmediatePropagation).toHaveBeenCalledOnce()

		app._modalStack[0].close({ confirm: true })

		expect(pageWindow.removeEventListener).toHaveBeenCalledWith(
			'touchmove',
			expect.any(Function),
			true,
		)
		expect(app._modalPageTouchTarget).toBeNull()
	})

	it('keeps scrolling inside modal content and contains its overscroll', () => {
		const styles = fs.readFileSync(resolve(process.cwd(), 'src/pages/miniApp/miniApp.scss'), 'utf8')
		const maskRule = styles.match(/\.dimina-dialog-mask\s*\{([\s\S]*?)\n\}/)?.[1]
		const contentRule = styles.match(/\.dimina-dialog__content\s*\{([\s\S]*?)\n\t\}/)?.[1]

		expect(maskRule).toMatch(/touch-action:\s*none/)
		expect(contentRule).toMatch(/overflow-y:\s*auto/)
		expect(contentRule).toMatch(/overscroll-behavior:\s*contain/)
		expect(contentRule).toMatch(/touch-action:\s*pan-y/)
	})
})
