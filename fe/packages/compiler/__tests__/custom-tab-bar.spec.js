import fs from 'node:fs'
import os from 'node:os'
import path from 'node:path'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { getComponent, getPages, storeInfo } from '../src/env.js'

const INTERNAL_COMPONENT_NAME = '__dimina_custom_tab_bar__'

describe('custom tabBar compilation', () => {
	let tempDir

	beforeEach(() => {
		tempDir = fs.mkdtempSync(path.join(os.tmpdir(), 'custom-tab-bar-'))
		fs.writeFileSync(path.join(tempDir, 'project.config.json'), JSON.stringify({ appid: 'custom-tab-bar-test' }))
		for (const page of ['home', 'message', 'detail']) {
			const pageDir = path.join(tempDir, 'pages', page)
			fs.mkdirSync(pageDir, { recursive: true })
			fs.writeFileSync(path.join(pageDir, 'index.json'), '{}')
		}
	})

	afterEach(() => {
		vi.restoreAllMocks()
		fs.rmSync(tempDir, { recursive: true, force: true })
	})

	it('injects custom-tab-bar/index only into configured tab pages', () => {
		fs.writeFileSync(path.join(tempDir, 'app.json'), JSON.stringify({
			pages: ['pages/home/index', 'pages/message/index', 'pages/detail/index'],
			tabBar: {
				custom: true,
				list: [
					{ pagePath: 'pages/home/index', text: 'Home' },
					{ pagePath: 'pages/message/index', text: 'Messages' },
				],
			},
		}))

		const tabBarDir = path.join(tempDir, 'custom-tab-bar')
		fs.mkdirSync(tabBarDir, { recursive: true })
		fs.writeFileSync(path.join(tabBarDir, 'index.json'), JSON.stringify({ component: true }))

		storeInfo(tempDir)
		const { mainPages } = getPages()
		const home = mainPages.find(page => page.path === 'pages/home/index')
		const message = mainPages.find(page => page.path === 'pages/message/index')
		const detail = mainPages.find(page => page.path === 'pages/detail/index')

		expect(home.usingComponents[INTERNAL_COMPONENT_NAME]).toBe('/custom-tab-bar/index')
		expect(message.usingComponents[INTERNAL_COMPONENT_NAME]).toBe('/custom-tab-bar/index')
		expect(detail.usingComponents).not.toHaveProperty(INTERNAL_COMPONENT_NAME)
		expect(getComponent('/custom-tab-bar/index')).toMatchObject({
			path: '/custom-tab-bar/index',
			component: true,
		})
	})

	it('does not inject a missing custom tabBar component', () => {
		fs.writeFileSync(path.join(tempDir, 'app.json'), JSON.stringify({
			pages: ['pages/home/index'],
			tabBar: {
				custom: true,
				list: [{ pagePath: 'pages/home/index', text: 'Home' }],
			},
		}))
		vi.spyOn(console, 'warn').mockImplementation(() => {})

		storeInfo(tempDir)
		const { mainPages } = getPages()

		expect(mainPages[0].usingComponents).not.toHaveProperty(INTERNAL_COMPONENT_NAME)
		expect(console.warn).toHaveBeenCalledWith(
			'[env] tabBar.custom 已启用，但找不到 custom-tab-bar/index.json',
		)
	})
})
