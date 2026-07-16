import { describe, expect, it } from 'vitest'
import { serializeProps } from '../src/core/utils'
import { Component } from '../src/instance/component/component'
import { ComponentModule } from '../src/instance/component/component-module'

function createComponent(properties, incomingProperties = {}) {
	const componentModule = new ComponentModule({
		properties,
	}, {
		component: true,
	})
	return new Component(componentModule, {
		bridgeId: 'bridge-properties',
		moduleId: `component-${Math.random()}`,
		path: '/property-component',
		pageId: 'page-properties',
		parentId: 'page-properties',
		properties: incomingProperties,
	})
}

describe('component property normalization', () => {
	it('serializes the primary type before optionalTypes', () => {
		expect(serializeProps({
			mixed: { type: String, optionalTypes: [Boolean, Object] },
		})).toEqual({
			mixed: {
				type: ['s', 'b', 'o'],
				default: '',
			},
		})
	})

	it('uses declared defaults only when a property is absent', async () => {
		const component = createComponent({
			label: { type: String, value: 'default-label' },
			items: Array,
		})

		await component.init()

		expect(component.data.label).toBe('default-label')
		expect(component.data.items).toEqual([])
	})

	it('converts initial and updated values with mini-program semantics', async () => {
		const component = createComponent({
			label: String,
			active: Boolean,
			count: Number,
			items: Array,
			mixed: { type: String, optionalTypes: [Boolean] },
		}, {
			label: null,
			active: '',
			count: '12.5',
			items: {},
			mixed: true,
		})

		await component.init()
		expect(component.data).toMatchObject({
			label: '',
			active: false,
			count: 12.5,
			items: [],
			mixed: true,
		})

		component.tO({
			label: false,
			active: 'false',
			count: 'invalid',
		})
		expect(component.data).toMatchObject({
			label: 'false',
			active: true,
			count: 0,
		})
	})

	it('does not share implicit array defaults between component instances', async () => {
		const first = createComponent({ items: Array })
		const second = createComponent({ items: Array })
		await first.init()
		await second.init()

		first.data.items.push('first')
		expect(second.data.items).toEqual([])
	})
})
