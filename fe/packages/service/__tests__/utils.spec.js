import { describe, expect, it, vi } from 'vitest'
import { filterInvokeObserver } from '../src/core/utils'

describe('数据监听器触发匹配逻辑', () => {
	const funAB = vi.fn((numberA, numberB) => {
		return numberA + numberB
	})

	const funB = vi.fn((numberB) => {
		return numberB
	})

	const data = { numberA: 1, numberB: 2 }
	const observers = {
		'numberA, numberB': funAB,
		'numberB': funB,
	}

	Object.keys(data).forEach((key) => {
		filterInvokeObserver(key, observers, data)
	})

	it('执行函数B', () => {
		expect(funB).toHaveReturnedWith(2)
	})

	it('执行函数AB', () => {
		expect(funAB).toHaveReturnedWith(3)
	})

	const data2 = {
		some: {
			subfield: 6,
		},
		arr: Array.from({ length: 14 }).fill(8),
	}

	const funSubfield = vi.fn((subfield) => {
		// 1.设置 some.subfield 时触发
		// 2.设置 some 也会触发
		return subfield === data2.some.subfield
	})

	const funArr12 = vi.fn((arr12) => {
		// 1.设置 arr[12] 时触发
		return arr12 === data2.arr[12]
	})

	const funArr = vi.fn((arr) => {
		// 2.设置 arr 也会触发
		return arr === data2.arr
	})

	const observers2 = {
		'some.subfield': funSubfield,
		'arr[12]': funArr12,
		'arr': funArr,
	}

	const keys = ['some.subfield', 'arr[12]']
	keys.forEach((key) => {
		filterInvokeObserver(key, observers2, data2)
	})

	it('监听子数据字段', () => {
		expect(funSubfield).toHaveReturnedWith(true)
	})

	it('监听子数据数组中某个字段', () => {
		expect(funArr12).toHaveReturnedWith(true)
	})

	it('监听子数据数组字段', () => {
		expect(funArr).toHaveReturnedWith(true)
	})

	it('监听所有子数据字段的变化', () => {
		const data = {
			some: {
				field: 10,
			},
		}

		const funSubfield = vi.fn((field) => {
			return field === data.some.field
		})
		const observers = {
			'some.field.**': funSubfield,
		}
		filterInvokeObserver('some.field', observers, data)
		filterInvokeObserver('some.field.sub', observers, data)
		filterInvokeObserver('some', observers, data)
		expect(funSubfield).toHaveNthReturnedWith(1, true)
		expect(funSubfield).toHaveNthReturnedWith(2, true)
		expect(funSubfield).toHaveNthReturnedWith(3, true)
	})

	it('监听全部', () => {
		const data = {
			a: 1,
			b: 2,
			c: 3,
		}

		const funAll = vi.fn((res) => {
			return data === res
		})
		const observers = {
			'**': funAll,
		}

		filterInvokeObserver('b', observers, data)
		expect(funAll).toHaveReturnedWith(true)
	})
})
