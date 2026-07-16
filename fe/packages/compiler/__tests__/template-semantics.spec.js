import fs from 'node:fs'
import os from 'node:os'
import path from 'node:path'
import { afterEach, beforeEach, describe, expect, it } from 'vitest'

describe('mini-program template semantics', () => {
	let tempDir
	let originalTargetPath
	let compileIndex = 0

	beforeEach(() => {
		originalTargetPath = process.env.TARGET_PATH
		tempDir = fs.mkdtempSync(path.join(os.tmpdir(), 'template-semantics-'))
	})

	afterEach(() => {
		if (originalTargetPath) process.env.TARGET_PATH = originalTargetPath
		else delete process.env.TARGET_PATH
		fs.rmSync(tempDir, { recursive: true, force: true })
	})

	async function compilePage(template) {
		const pagePath = `pages/index-${compileIndex++}`
		fs.writeFileSync(path.join(tempDir, 'app.json'), JSON.stringify({
			pages: [pagePath],
		}))
		fs.writeFileSync(path.join(tempDir, 'project.config.json'), JSON.stringify({
			appid: 'template-semantics',
		}))
		fs.mkdirSync(path.join(tempDir, 'pages'), { recursive: true })
		fs.writeFileSync(path.join(tempDir, `${pagePath}.json`), JSON.stringify({
			usingComponents: {
				'info-card': '/components/info-card',
			},
		}))
		fs.writeFileSync(path.join(tempDir, `${pagePath}.wxml`), template)
		fs.mkdirSync(path.join(tempDir, 'components/info-card'), { recursive: true })
		fs.writeFileSync(path.join(tempDir, 'components/info-card/index.json'), JSON.stringify({
			component: true,
		}))
		fs.writeFileSync(path.join(tempDir, 'components/info-card/index.wxml'), '<view><slot name="info"></slot></view>')

		const outputDir = path.join(tempDir, 'dist')
		fs.mkdirSync(outputDir, { recursive: true })
		process.env.TARGET_PATH = outputDir

		const { getPages, storeInfo } = await import('../src/env.js')
		storeInfo(tempDir)
		const { compileML } = await import('../src/core/view-compiler.js')
		await compileML(getPages().mainPages, null, { completedTasks: 0 })
		return fs.readFileSync(path.join(outputDir, `main/${pagePath.replace(/\//g, '_')}.js`), 'utf8')
	}

	it('keeps all nodes from duplicate named slots', async () => {
		const output = await compilePage(`
			<info-card>
				<text slot="info">成功</text>
				<text slot="info">失败</text>
			</info-card>
		`)

		expect(output).toContain('\\u6210\\u529F')
		expect(output).toContain('\\u5931\\u8D25')
	})

	it('evaluates wx:if inside the wx:for item scope', async () => {
		const output = await compilePage(`
			<view wx:for="{{ list }}" wx:for-item="entry" wx:key="id" wx:if="{{ entry.visible }}">
				{{entry.name}}
			</view>
		`)

		expect(output).toMatch(/_renderList\([^]*=>[^]*\.visible\?/)
		expect(output.indexOf('.visible')).toBeGreaterThan(output.indexOf('_renderList'))
	})

	it('keeps the loop item scope inside a named slot', async () => {
		const output = await compilePage(`
			<info-card>
				<text slot="info" wx:for="{{ list }}" wx:if="{{ item.visible }}">
					{{item.name}}
				</text>
			</info-card>
		`)

		expect(output).toMatch(/info:_withCtx\([^]*_renderList\([^]*=>[^]*\.visible\?/)
		expect(output.indexOf('.visible')).toBeGreaterThan(output.indexOf('_renderList'))
	})
})
