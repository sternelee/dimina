import { describe, expect, it } from 'vitest'
import { camelCaseToUnderscore, toCamelCase } from '../src/core/utils'

describe('自定义数据转换', () => {
	it('连字符写法会转换成驼峰写法', () => {
		expect(toCamelCase('element-type')).toEqual('elementType')
	})

	it('大写字符会自动转成小写字符', () => {
		expect(toCamelCase('elementType')).toEqual('elementtype')
	})
})

describe('组件名转下划线', () => {
	it('一个单词', () => {
		expect(camelCaseToUnderscore('Switch')).toEqual('switch')
	})

	it('两个单词', () => {
		expect(camelCaseToUnderscore('PickerView')).toEqual('picker-view')
	})

	it('三个单词', () => {
		expect(camelCaseToUnderscore('PickerViewColumn')).toEqual('picker-view-column')
	})
})
