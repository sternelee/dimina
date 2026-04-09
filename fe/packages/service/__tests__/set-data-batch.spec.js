import { callback as callbackRegistry } from '@dimina/common'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { resetUpdateQueues } from '../src/core/update-queue'
import runtime from '../src/core/runtime'
import { Component } from '../src/instance/component/component'
import { Page } from '../src/instance/page/page'

describe('setData update batching', () => {
	const sentMessages = []

	beforeEach(() => {
		sentMessages.length = 0
		resetUpdateQueues()
		runtime.instances = {}
		globalThis.DiminaServiceBridge.publish = vi.fn((_bridgeId, msg) => {
			sentMessages.push(msg)
			return Promise.resolve()
		})
	})

	it('batches multiple page setData calls in the same tick', async () => {
		const page = {
			data: {},
			initd: true,
			bridgeId: 'bridge-1',
			__id__: 'page-1',
			__childPropsBindings__: {},
		}
		runtime.instances[page.bridgeId] = {
			[page.__id__]: page,
		}

		Page.prototype.setData.call(page, { count: 1 })
		Page.prototype.setData.call(page, { name: 'dimina' })

		expect(sentMessages).toEqual([])

		await Promise.resolve()

		expect(sentMessages).toHaveLength(1)
		expect(sentMessages[0]).toMatchObject({
			type: 'ub',
			target: 'render',
			body: {
				bridgeId: page.bridgeId,
				callbackIds: [],
				updates: [
					{
						moduleId: page.__id__,
						data: {
							count: 1,
							name: 'dimina',
						},
					},
				],
			},
		})
	})

	it('flushes groupSetData once after the group ends and includes synced children', () => {
		const child = {
			__id__: 'child-1',
			__parentId__: 'component-1',
			__pendingSyncedProps__: {},
			__info__: {
				properties: {
					count: {},
				},
			},
			data: {
				count: 0,
			},
			tO: vi.fn(function tO(data) {
				Object.assign(this.data, data)
			}),
		}
		const component = {
			data: {},
			initd: true,
			bridgeId: 'bridge-1',
			__id__: 'component-1',
			__info__: {},
			__childPropsBindings__: {
				'child-1': {
					count: {
						expression: 'count',
						dependencies: ['count'],
						isSimple: true,
					},
				},
			},
			__groupSetDataMode__: false,
			__groupSetDataBuffer__: {},
		}
		runtime.instances[component.bridgeId] = {
			[component.__id__]: component,
			[child.__id__]: child,
		}

		Component.prototype.groupSetData.call(component, function groupUpdate() {
			Component.prototype.setData.call(this, { count: 1 })
			Component.prototype.setData.call(this, { name: 'dimina' })
			expect(sentMessages).toEqual([])
		})

		expect(sentMessages).toHaveLength(1)
		expect(sentMessages[0]).toMatchObject({
			type: 'ub',
			target: 'render',
			body: {
				bridgeId: component.bridgeId,
				updates: [
					{
						moduleId: component.__id__,
						data: {
							count: 1,
							name: 'dimina',
						},
					},
					{
						moduleId: child.__id__,
						data: {
							count: 1,
						},
					},
				],
			},
		})
		expect(child.tO).toHaveBeenCalledWith({ count: 1 })
		expect(child.__pendingSyncedProps__).toEqual({ count: 1 })
	})

	it('defers setData callback until the render layer acknowledges the batch', async () => {
		const page = {
			data: {},
			initd: true,
			bridgeId: 'bridge-1',
			__id__: 'page-1',
			__childPropsBindings__: {},
		}
		const callback = vi.fn(function onSetData() {
			expect(this).toBe(page)
		})
		runtime.instances[page.bridgeId] = {
			[page.__id__]: page,
		}

		Page.prototype.setData.call(page, { count: 1 }, callback)
		expect(callback).not.toHaveBeenCalled()

		await Promise.resolve()

		expect(callback).not.toHaveBeenCalled()
		expect(sentMessages[0].body.callbackIds).toEqual([expect.any(String)])

		callbackRegistry.invoke(sentMessages[0].body.callbackIds[0])

		expect(callback).toHaveBeenCalledTimes(1)
	})
})
