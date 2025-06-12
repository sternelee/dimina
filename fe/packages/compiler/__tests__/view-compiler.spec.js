import { describe, expect, it } from 'vitest'
import { generateVModelTemplate, parseBraceExp, parseClassRules, parseKeyExpression, splitWithBraces } from '../src/core/view-compiler'

describe('parseKeyExpression - 解析 key 表达式', () => {
	it('普通属性名 - 应该添加 item 前缀', () => {
		expect(parseKeyExpression('index')).toEqual('item.index')
	})
	
	it('已有 item 前缀的属性 - 应该保持不变', () => {
		expect(parseKeyExpression('item.index')).toEqual('item.index')
	})

	it('双花括号包裹的属性 - 应该去除花括号', () => {
		expect(parseKeyExpression('{{ item.index }}')).toEqual('item.index')
	})

	it('双花括号包裹的简单属性 - 应该添加 item 前缀', () => {
		expect(parseKeyExpression('{{ text }}')).toEqual('item.text')
	})

	it('*this 关键字 - 应该转换为 toString 方法', () => {
		expect(parseKeyExpression('*this')).toEqual('item.toString()')
	})

	it('双花括号包裹的 this - 应该转换为 toString 方法', () => {
		expect(parseKeyExpression('{{ this }}')).toEqual('item.toString()')
	})
	
	it('正整数 - 应该直接返回数字', () => {
		expect(parseKeyExpression('1')).toEqual('1')
	})
	
	it('负整数 - 应该直接返回负数', () => {
		expect(parseKeyExpression('-1')).toEqual('-1')
	})
	
	it('正小数 - 应该直接返回小数', () => {
		expect(parseKeyExpression('3.14')).toEqual('3.14')
	})
	
	it('负小数 - 应该直接返回负小数', () => {
		expect(parseKeyExpression('-2.5')).toEqual('-2.5')
	})
	
	it('零 - 应该直接返回零', () => {
		expect(parseKeyExpression('0')).toEqual('0')
	})
	
	it('双花括号包裹的正整数 - 应该返回字符串形式', () => {
		expect(parseKeyExpression('{{ 1 }}')).toEqual('item.1')
	})
	
	it('双花括号包裹的负整数 - 应该返回字符串形式', () => {
		expect(parseKeyExpression('{{ -1 }}')).toEqual('item.-1')
	})
	
	it('字符串拼接表达式 - 应该正确处理拼接', () => {
		expect(parseKeyExpression('1-{{index}}')).toEqual('\'1-\'+item.index')
	})

	it('字符串拼接对象属性表达式 - 应该正确处理拼接', () => {
		expect(parseKeyExpression('1-{{item.index}}')).toEqual('\'1-\'+item.index')
	})
})

describe('parseBraceExp - 解析双花括号表达式', () => {
	it('纯文本字符串 - 应该包裹引号', () => {
		expect(parseBraceExp('item-container')).toEqual('\'item-container\'')
	})

	it('对象字面量表达式 - 应该去除外层花括号', () => {
		expect(parseBraceExp('{{text: \'I am template\'}}')).toEqual('text: \'I am template\'')
	})

	it('对象属性访问 - 应该去除花括号', () => {
		expect(parseBraceExp('{{item.name}}')).toEqual('item.name')
	})

	it('三层嵌套花括号 - 应该保留内层花括号', () => {
		expect(parseBraceExp('{{{item.name}}}')).toEqual('{item.name}')
	})

	it('三层嵌套对象属性 - 应该保留内层花括号', () => {
		expect(parseBraceExp('{{{background: \'transparent\'}}}')).toEqual(
			'{background: \'transparent\'}',
		)
	})

	it('混合文本和表达式 - 应该正确拼接', () => {
		expect(parseBraceExp('item-container item-container-{{index}}')).toEqual(
			'\'item-container item-container-\'+index',
		)
	})

	it('三元运算符表达式 - 应该用括号包裹', () => {
		expect(parseBraceExp('{{showReserveTime ? \'justify-content: space-between;\' : \'justify-content: flex-end;\'}}')).toEqual(
			'(showReserveTime ? \'justify-content: space-between;\' : \'justify-content: flex-end;\')',
		)
	})

	it('逻辑运算符表达式 - 应该保持原样', () => {
		expect(parseBraceExp('{{item.data.originFloor && item.data.originFloor.text || \'description\'}}')).toEqual(
			'item.data.originFloor && item.data.originFloor.text || \'description\'',
		)
	})

	it('URL 模板字符串 - 应该正确转义引号', () => {
		expect(parseBraceExp('background:url(\'{{imageList}}\')')).toEqual(
			'\'background:url(\\\'\'+imageList+\'\\\')\'',
		)
	})
})

describe('splitWithBraces - 按空格分割字符串（保留花括号）', () => {
	it('简单空格分割 - 应该返回数组', () => {
		expect(splitWithBraces('a b')).toEqual(['a', 'b'])
	})
	
	it('空格和花括号表达式 - 应该保持花括号完整', () => {
		expect(splitWithBraces('a {{b}}')).toEqual(['a', '{{b}}'])
	})
	
	it('连字符和花括号混合 - 应该作为一个整体', () => {
		expect(splitWithBraces('a b-{{c}}')).toEqual(['a', 'b-{{c}}'])
	})
	
	it('花括号紧跟文本 - 应该作为一个整体', () => {
		expect(splitWithBraces('a b{{c}}')).toEqual(['a', 'b{{c}}'])
	})
	
	it('花括号在文本中间 - 应该作为一个整体', () => {
		expect(splitWithBraces('a {{b}}c')).toEqual(['a', '{{b}}c'])
	})
	
	it('花括号内前置空格 - 应该保留空格', () => {
		expect(splitWithBraces('a b-{{ c}}')).toEqual(['a', 'b-{{ c}}'])
	})
	
	it('花括号内后置空格 - 应该保留空格', () => {
		expect(splitWithBraces('a b-{{c }}')).toEqual(['a', 'b-{{c }}'])
	})
	
	it('花括号内前后空格 - 应该保留所有空格', () => {
		expect(splitWithBraces('a b-{{ c }}')).toEqual(['a', 'b-{{ c }}'])
	})
})

describe('parseClassRules - 解析 CSS 类名规则', () => {
	it('纯文本类名 - 应该包裹引号', () => {
		expect(parseClassRules('item-container')).toEqual('\'item-container\'')
	})

	it('单个花括号表达式 - 应该去除花括号', () => {
		expect(parseClassRules('{{item-container}}')).toEqual('item-container')
	})

	it('多个类名和表达式混合 - 应该返回数组格式', () => {
		expect(
			parseClassRules('confirm-button {{disabled ? \'disabled\' : \'\'}} {{round ? \'round-button\' : \'\'}}'),
		).toEqual('[\'confirm-button\',(disabled ? \'disabled\' : \'\'),(round ? \'round-button\' : \'\')]')
	})

	it('文本和表达式拼接 - 应该返回数组格式', () => {
		expect(parseClassRules('item-container item-container-{{index}}')).toEqual(
			'[\'item-container\',\'item-container-\'+index]',
		)
	})
})

describe('generateVModelTemplate - 生成 v-model 模板', () => {
	it('逻辑与表达式 - 应该生成条件赋值', () => {
		expect(generateVModelTemplate('tempOffset && finalOffset')).to.equal(
			'tempOffset ? (finalOffset = $event) : (tempOffset = $event)',
		)
	})

	it('逻辑或表达式 - 应该生成条件赋值', () => {
		expect(generateVModelTemplate('tempOffset || finalOffset')).to.equal(
			'tempOffset ? (tempOffset = $event) : (finalOffset = $event)',
		)
	})

	it('三元表达式 - 应该生成条件赋值', () => {
		expect(generateVModelTemplate('tempOffset ? tempOffset : finalOffset')).to.equal(
			'tempOffset ? (tempOffset = $event) : (finalOffset = $event)',
		)
	})

	it('无效表达式 - 应该返回 false', () => {
		expect(generateVModelTemplate('invalidExpression')).to.equal(false)
	})

	it('带空格的表达式 - 应该正确处理', () => {
		expect(generateVModelTemplate('  tempOffset  &&  finalOffset  ')).to.equal(
			'tempOffset ? (finalOffset = $event) : (tempOffset = $event)',
		)
	})

	it('简短变量名 - 应该正确处理', () => {
		expect(generateVModelTemplate('a || b')).to.equal('a ? (a = $event) : (b = $event)')
	})
})
