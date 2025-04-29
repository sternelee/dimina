import { describe, expect, it } from 'vitest'
import viewCompiler from '../src/core/view-compiler'

const { parseBraceExp, parseClassRules, splitWithBraces, parseKeyExpression } = viewCompiler

describe('解析 key 表达式的值', () => {
	it('简单取值', () => {
		expect(parseKeyExpression('index')).toEqual('\'item.index\'')
	})
	it('简单对象取值', () => {
		expect(parseKeyExpression('item.index')).toEqual('\'item.index\'')
	})

	it('简单表达式对象取值', () => {
		expect(parseKeyExpression('{{ item.index }}')).toEqual('\'item.index\'')
	})

	it('字符串表达式', () => {
		expect(parseKeyExpression('1-{{index}}')).toEqual('\'1-\'+item.index')
	})

	it('字符串对象表达式', () => {
		expect(parseKeyExpression('1-{{item.index}}')).toEqual('\'1-\'+item.index')
	})
})

describe('解析 {{}} 表达式的值', () => {
	it('简单无表达式', () => {
		expect(parseBraceExp('item-container')).toEqual('\'item-container\'')
	})

	it('模板表达式', () => {
		expect(parseBraceExp('{{text: \'I am template\'}}')).toEqual('text: \'I am template\'')
	})

	it('对象表达式', () => {
		expect(parseBraceExp('{{item.name}}')).toEqual('item.name')
	})

	it('三层模板表达式', () => {
		expect(parseBraceExp('{{{item.name}}}')).toEqual('{item.name}')
	})

	it('三层模板属性表达式', () => {
		expect(parseBraceExp('{{{background: \'transparent\'}}}')).toEqual(
			'{background: \'transparent\'}',
		)
	})

	it('多样式单表达式', () => {
		expect(parseBraceExp('item-container item-container-{{index}}')).toEqual(
			'\'item-container item-container-\'+index',
		)
	})

	it('三目表达式', () => {
		expect(parseBraceExp('{{showReserveTime ? \'justify-content: space-between;\' : \'justify-content: flex-end;\'}}')).toEqual(
			'(showReserveTime ? \'justify-content: space-between;\' : \'justify-content: flex-end;\')',
		)
	})

	it('多重判断表达式', () => {
		expect(parseBraceExp('{{item.data.originFloor && item.data.originFloor.text || \'description\'}}')).toEqual(
			'item.data.originFloor && item.data.originFloor.text || \'description\'',
		)
	})

	it('属性表达式', () => {
		expect(parseBraceExp('background:url(\'{{imageList}}\')')).toEqual(
			'\'background:url(\\\'\'+imageList+\'\\\')\'',
		)
	})
})

describe('字符串按空格拆分', () => {
	it('空格字符串', () => {
		expect(splitWithBraces('a b')).toEqual(['a', 'b'])
	})
	it('空格和表达式', () => {
		expect(splitWithBraces('a {{b}}')).toEqual(['a', '{{b}}'])
	})
	it('空格，表达式和连字符', () => {
		expect(splitWithBraces('a b-{{c}}')).toEqual(['a', 'b-{{c}}'])
	})
	it('空格，表达式在后面', () => {
		expect(splitWithBraces('a b{{c}}')).toEqual(['a', 'b{{c}}'])
	})
	it('空格，表达式在中间', () => {
		expect(splitWithBraces('a {{b}}c')).toEqual(['a', '{{b}}c'])
	})
	it('空格，表达式内带前空格', () => {
		expect(splitWithBraces('a b-{{ c}}')).toEqual(['a', 'b-{{ c}}'])
	})
	it('空格，表达式内带后空格', () => {
		expect(splitWithBraces('a b-{{c }}')).toEqual(['a', 'b-{{c }}'])
	})
	it('空格，表达式内带前后空格', () => {
		expect(splitWithBraces('a b-{{ c }}')).toEqual(['a', 'b-{{ c }}'])
	})
})

describe('解析样式类', () => {
	it('无表达式', () => {
		expect(parseClassRules('item-container')).toEqual('\'item-container\'')
	})

	it('简单表达式', () => {
		expect(parseClassRules('{{item-container}}')).toEqual('item-container')
	})

	it('多样式多表达式', () => {
		expect(
			parseClassRules('confirm-button {{disabled ? \'disabled\' : \'\'}} {{round ? \'round-button\' : \'\'}}'),
		).toEqual('[\'confirm-button\',(disabled ? \'disabled\' : \'\'),(round ? \'round-button\' : \'\')]')
	})

	it('多样式单表达式', () => {
		expect(parseClassRules('item-container item-container-{{index}}')).toEqual(
			'[\'item-container\',\'item-container-\'+index]',
		)
	})
})
