import { describe, it, expect, beforeEach, afterEach } from 'vitest'
import fs from 'node:fs'
import path from 'node:path'
import os from 'node:os'
import { storeInfo } from '../src/env.js'
import { compileJS } from '../src/core/logic-compiler.js'

describe('Require Path Resolution', () => {
	let tempDir
	let originalCwd

	beforeEach(() => {
		originalCwd = process.cwd()
		tempDir = fs.mkdtempSync(path.join(os.tmpdir(), 'require-test-'))
		process.chdir(tempDir)
	})

	afterEach(() => {
		process.chdir(originalCwd)
		if (fs.existsSync(tempDir)) {
			fs.rmSync(tempDir, { recursive: true, force: true })
		}
	})

	it('should resolve relative require paths correctly', async () => {
		// 创建测试文件结构
		fs.mkdirSync('pages/test', { recursive: true })
		fs.mkdirSync('libs', { recursive: true })
		fs.mkdirSync('utils', { recursive: true })
		
		// 创建 app.json
		fs.writeFileSync('app.json', JSON.stringify({
			pages: ['pages/test/index']
		}))
		
		// 创建 libs/Mixins.js
		fs.writeFileSync('libs/Mixins.js', `
			module.exports = {
				init: function() {
					return 'Mixins initialized'
				}
			}
		`)
		
		// 创建 utils/util.js
		fs.writeFileSync('utils/util.js', `
			module.exports = {
				formatTime: function(time) {
					return time.toISOString()
				}
			}
		`)
		
		// 创建页面文件，使用不同类型的 require
		fs.writeFileSync('pages/test/index.js', `
			// 相对路径 require（向上两级）
			const Mixins = require('../../libs/Mixins.js')
			
			// 相对路径 require（向上一级）
			const util = require('../../utils/util')
			
			// 当前目录相对路径
			const helper = require('./helper.js')
			
			Page({
				onLoad() {
					console.log(Mixins.init())
					console.log(util.formatTime(new Date()))
					console.log(helper.test())
				}
			})
		`)
		
		// 创建同级的 helper.js
		fs.writeFileSync('pages/test/helper.js', `
			module.exports = {
				test: function() {
					return 'helper test'
				}
			}
		`)
		
		fs.writeFileSync('pages/test/index.json', JSON.stringify({
			navigationBarTitleText: '测试页面'
		}))
		
		// 执行配置收集
		storeInfo(tempDir)
		
		// 模拟编译过程
		const pages = {
			mainPages: [{ path: 'pages/test/index' }]
		}
		
		const progress = { completedTasks: 0 }
		const result = await compileJS(pages.mainPages, null, null, progress)
		
		expect(result).toBeDefined()
		expect(result.length).toBeGreaterThan(0)
		
		// 获取页面模块的编译结果
		const pageModule = result.find(module => module.path === 'pages/test/index')
		expect(pageModule).toBeDefined()
		
		// 验证编译后的代码
		const compiledCode = pageModule.code
		
		// 验证所有相对路径都被转换为绝对路径
		expect(compiledCode).toContain('require("/libs/Mixins")')
		expect(compiledCode).toContain('require("/utils/util")')
		expect(compiledCode).toContain('require("/pages/test/helper")')
		
		// 验证不包含相对路径的 require
		expect(compiledCode).not.toMatch(/require\(['"]\.\.\//)
		expect(compiledCode).not.toMatch(/require\(['"]\.\//)
	})

	it('should handle npm package requires correctly', async () => {
		// 创建测试文件结构
		fs.mkdirSync('pages/npm-test', { recursive: true })
		fs.mkdirSync('miniprogram_npm/@vant/weapp/button', { recursive: true })
		
		// 创建 app.json
		fs.writeFileSync('app.json', JSON.stringify({
			pages: ['pages/npm-test/index']
		}))
		
		// 创建模拟的 npm 组件
		fs.writeFileSync('miniprogram_npm/@vant/weapp/button/index.js', `
			Component({
				properties: {
					text: String
				}
			})
		`)
		
		// 创建页面文件，使用 npm 包 require
		fs.writeFileSync('pages/npm-test/index.js', `
			// npm 包 require（@开头）
			const Button = require('@vant/weapp/button/index')
			
			// npm 包 require（miniprogram_npm 开头）
			const Button2 = require('miniprogram_npm/@vant/weapp/button/index')
			
			Page({
				onLoad() {
					console.log('Button:', Button)
					console.log('Button2:', Button2)
				}
			})
		`)
		
		fs.writeFileSync('pages/npm-test/index.json', JSON.stringify({
			navigationBarTitleText: 'NPM 测试'
		}))
		
		// 执行配置收集
		storeInfo(tempDir)
		
		// 模拟编译过程
		const pages = {
			mainPages: [{ path: 'pages/npm-test/index' }]
		}
		
		const progress = { completedTasks: 0 }
		const result = await compileJS(pages.mainPages, null, null, progress)
		
		expect(result).toBeDefined()
		
		// 获取页面模块的编译结果
		const pageModule = result.find(module => module.path === 'pages/npm-test/index')
		expect(pageModule).toBeDefined()
		
		// 验证编译后的代码
		const compiledCode = pageModule.code
		
		// 验证 npm 包路径被正确转换
		expect(compiledCode).toContain('require("/miniprogram_npm/@vant/weapp/button/index")')
		
		// 验证不包含原始的 @ 开头的 require
		expect(compiledCode).not.toMatch(/require\(['"]@vant/)
	})

	it('should handle mixed import and require statements', async () => {
		// 创建测试文件结构
		fs.mkdirSync('pages/mixed', { recursive: true })
		fs.mkdirSync('utils', { recursive: true })
		fs.mkdirSync('libs', { recursive: true })
		
		// 创建 app.json
		fs.writeFileSync('app.json', JSON.stringify({
			pages: ['pages/mixed/index']
		}))
		
		// 创建工具模块
		fs.writeFileSync('utils/api.js', `
			exports.request = function() { return 'api request' }
		`)
		
		fs.writeFileSync('libs/helper.js', `
			module.exports = { help: function() { return 'help' } }
		`)
		
		// 创建页面文件，混合使用 import 和 require
		fs.writeFileSync('pages/mixed/index.js', `
			// ES6 import
			import { request } from '../../utils/api'
			
			// CommonJS require
			const helper = require('../../libs/helper.js')
			
			Page({
				onLoad() {
					console.log(request())
					console.log(helper.help())
				}
			})
		`)
		
		fs.writeFileSync('pages/mixed/index.json', JSON.stringify({
			navigationBarTitleText: '混合测试'
		}))
		
		// 执行配置收集
		storeInfo(tempDir)
		
		// 模拟编译过程
		const pages = {
			mainPages: [{ path: 'pages/mixed/index' }]
		}
		
		const progress = { completedTasks: 0 }
		const result = await compileJS(pages.mainPages, null, null, progress)
		
		expect(result).toBeDefined()
		
		// 获取页面模块的编译结果
		const pageModule = result.find(module => module.path === 'pages/mixed/index')
		expect(pageModule).toBeDefined()
		
		// 验证编译后的代码
		const compiledCode = pageModule.code
		
		// 验证所有路径都被转换为绝对路径
		expect(compiledCode).toContain('require("/utils/api")')
		expect(compiledCode).toContain('require("/libs/helper")')
		
		// 验证没有相对路径
		expect(compiledCode).not.toMatch(/require\(['"]\.\.\//)
		
		// 验证没有 import 语句
		expect(compiledCode).not.toContain('import ')
	})

	it('should handle absolute path requires', async () => {
		// 创建测试文件结构
		fs.mkdirSync('pages/absolute', { recursive: true })
		fs.mkdirSync('utils', { recursive: true })
		
		// 创建 app.json
		fs.writeFileSync('app.json', JSON.stringify({
			pages: ['pages/absolute/index']
		}))
		
		// 创建工具模块
		fs.writeFileSync('utils/tools.js', `
			exports.process = function() { return 'processed' }
		`)
		
		// 创建页面文件，使用绝对路径 require
		fs.writeFileSync('pages/absolute/index.js', `
			// 绝对路径 require（应该保持不变或被正确处理）
			const tools = require('/utils/tools')
			
			Page({
				onLoad() {
					console.log(tools.process())
				}
			})
		`)
		
		fs.writeFileSync('pages/absolute/index.json', JSON.stringify({
			navigationBarTitleText: '绝对路径测试'
		}))
		
		// 执行配置收集
		storeInfo(tempDir)
		
		// 模拟编译过程
		const pages = {
			mainPages: [{ path: 'pages/absolute/index' }]
		}
		
		const progress = { completedTasks: 0 }
		const result = await compileJS(pages.mainPages, null, null, progress)
		
		expect(result).toBeDefined()
		
		// 获取页面模块的编译结果
		const pageModule = result.find(module => module.path === 'pages/absolute/index')
		expect(pageModule).toBeDefined()
		
		// 验证编译后的代码
		const compiledCode = pageModule.code
		
		// 验证绝对路径被正确处理
		// 注意：绝对路径会被 resolve 函数相对于当前文件进行解析
		expect(compiledCode).toContain('require("/pages/absolute/utils/tools")')
	})

	it('should handle require with file extensions', async () => {
		// 创建测试文件结构
		fs.mkdirSync('pages/ext-test', { recursive: true })
		fs.mkdirSync('utils', { recursive: true })
		
		// 创建 app.json
		fs.writeFileSync('app.json', JSON.stringify({
			pages: ['pages/ext-test/index']
		}))
		
		// 创建工具模块
		fs.writeFileSync('utils/module1.js', `exports.m1 = 'module1'`)
		fs.writeFileSync('utils/module2.ts', `export const m2 = 'module2'`)
		
		// 创建页面文件，require 包含和不包含扩展名
		fs.writeFileSync('pages/ext-test/index.js', `
			// 带 .js 扩展名
			const m1 = require('../../utils/module1.js')
			
			// 不带扩展名
			const m2 = require('../../utils/module2')
			
			// 带 .ts 扩展名
			const m3 = require('../../utils/module2.ts')
			
			Page({
				onLoad() {
					console.log(m1, m2, m3)
				}
			})
		`)
		
		fs.writeFileSync('pages/ext-test/index.json', JSON.stringify({
			navigationBarTitleText: '扩展名测试'
		}))
		
		// 执行配置收集
		storeInfo(tempDir)
		
		// 模拟编译过程
		const pages = {
			mainPages: [{ path: 'pages/ext-test/index' }]
		}
		
		const progress = { completedTasks: 0 }
		const result = await compileJS(pages.mainPages, null, null, progress)
		
		expect(result).toBeDefined()
		
		// 获取页面模块的编译结果
		const pageModule = result.find(module => module.path === 'pages/ext-test/index')
		expect(pageModule).toBeDefined()
		
		// 验证编译后的代码
		const compiledCode = pageModule.code
		
		// 验证路径被转换且扩展名被移除
		expect(compiledCode).toContain('require("/utils/module1")')
		expect(compiledCode).toContain('require("/utils/module2")')
		
		// 验证没有 .js 或 .ts 扩展名（应该被移除）
		expect(compiledCode).not.toMatch(/require\(['"]\/utils\/module\d+\.(js|ts)/)
	})
})
