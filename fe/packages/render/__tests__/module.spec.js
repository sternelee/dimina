import { describe, expect, it } from 'vitest'
import { Module } from '../src/core/module'

describe('render module property transport', () => {
	it('keeps mini-program schemas while disabling Vue prop casting', () => {
		const module = new Module({})
		module.setInitialData({
			label: { type: ['s'], default: 'label' },
			mixed: { type: ['s', 'b'], default: '' },
			active: { type: ['b'], default: false },
		})

		expect(module.props).toEqual({
			label: { type: null },
			mixed: { type: null },
			active: { type: null },
		})
		expect(module.propertySchemas.label).toMatchObject({ type: String, value: 'label' })
		expect(module.propertySchemas.mixed).toMatchObject({
			type: String,
			optionalTypes: [Boolean],
		})
		expect(module.propertySchemas.active).toMatchObject({ type: Boolean, value: false })
	})
})
