import { describe, expect, it, vi } from 'vitest'
import runtime from '../src/core/runtime'
import { Component } from '../src/instance/component/component'
import { ComponentModule } from '../src/instance/component/component-module'

describe('Component.tO observer ordering', () => {
	it('executes property observers for initial component properties', () => {
		const componentModule = new ComponentModule({
			properties: {
				icon: {
					observer: 'observeIcon',
				},
			},
			methods: {
				observeIcon(icon) {
					this.setData({ _icon: icon ? { name: icon } : null })
				},
			},
		}, {
			component: true,
		})

		const component = new Component(componentModule, {
			bridgeId: 'bridge-1',
			moduleId: 'button-1',
			path: '/button',
			pageId: 'page-1',
			parentId: 'page-1',
			properties: {
				icon: 'add',
			},
		})

		component.init()

		expect(component.data._icon).toEqual({ name: 'add' })
	})

	it('executes property observers in reverse batch order after raw observers', () => {
		const calls = []
		const instance = {
			data: {
				show: false,
				position: 'center',
				name: 'fade',
			},
			__pendingSyncedProps__: {},
			__info__: {
				observers: {
					'show': () => {
						calls.push('observers:show')
					},
				},
				properties: {
					show: {
						observer: 'observeShow',
					},
					position: {
						observer: 'observeClass',
					},
				},
			},
			observeClass: vi.fn(function observeClass() {
				this.data.name = this.data.position
				calls.push(`observeClass:${this.data.name}`)
			}),
			observeShow: vi.fn(function observeShow() {
				calls.push(`observeShow:${this.data.name}`)
			}),
		}

		Component.prototype.tO.call(instance, {
			show: true,
			position: 'top',
		})

		expect(calls).toEqual([
			'observers:show',
			'observeClass:top',
			'observeShow:top',
		])
	})

	it('skips duplicate observer execution but keeps data in sync for identical render replay after parent sync', () => {
		const observeShow = vi.fn()
		const instance = {
			data: {
				show: false,
			},
			__pendingSyncedProps__: {
				show: true,
			},
			__info__: {
				observers: {},
				properties: {
					show: {
						observer: 'observeShow',
					},
				},
			},
			observeShow,
		}

		Component.prototype.tO.call(instance, {
			show: true,
		})

		expect(observeShow).not.toHaveBeenCalled()
		expect(instance.__pendingSyncedProps__).toEqual({})
		expect(instance.data.show).toBe(true)
	})

	it('does not throw when triggerEvent has no external listener', async () => {
		const instance = {
			bridgeId: 'bridge-1',
			__pageId__: 'page-1',
			__eventAttr__: {},
			id: 'tabs-1',
			dataset: {},
		}
		const trigger = vi.spyOn(runtime, 'triggerEvent')

		await expect(Component.prototype.triggerEvent.call(instance, 'change', { value: 'follow' })).resolves.toBeUndefined()
		expect(trigger).not.toHaveBeenCalled()

		trigger.mockRestore()
	})
})
