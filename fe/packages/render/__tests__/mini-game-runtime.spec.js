import { beforeEach, describe, expect, it, vi } from 'vitest'

const { send } = vi.hoisted(() => ({ send: vi.fn() }))
vi.mock('../src/core/message', () => ({ default: { send } }))

import runtime from '../src/core/runtime.js'

describe('mini game render surface', () => {
	beforeEach(() => {
		send.mockReset()
		document.body.innerHTML = ''
		runtime.canvasNodes.clear()
	})

	it('mounts one full-screen canvas and forwards touch events to service', () => {
		runtime.createGameCanvas({
			bridgeId: 'bridge-game',
			params: { nodeId: 'game-canvas', width: 390, height: 844, type: '2d' },
		})
		const canvas = document.querySelector('[data-dimina-game-canvas]')
		expect(canvas).toBeInstanceOf(HTMLCanvasElement)
		expect(canvas.width).toBe(390)
		expect(canvas.height).toBe(844)
		expect(canvas.style.touchAction).toBe('none')

		const event = new Event('touchstart', { cancelable: true })
		Object.defineProperties(event, {
			touches: { value: [{ identifier: 7, clientX: 12, clientY: 34, pageX: 12, pageY: 34, force: 0.5 }] },
			changedTouches: { value: [{ identifier: 7, clientX: 12, clientY: 34, pageX: 12, pageY: 34, force: 0.5 }] },
		})
		canvas.dispatchEvent(event)

		expect(send).toHaveBeenCalledWith(expect.objectContaining({
			type: 'gameTouch',
			target: 'service',
			body: expect.objectContaining({
				bridgeId: 'bridge-game',
				eventType: 'touchstart',
				touches: [expect.objectContaining({ identifier: 7, clientX: 12, clientY: 34 })],
			}),
		}))
	})
})
