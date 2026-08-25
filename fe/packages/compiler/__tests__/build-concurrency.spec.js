import fs from 'node:fs'
import os from 'node:os'
import path from 'node:path'
import { afterEach, describe, expect, it } from 'vitest'
import build from '../src/index.js'

describe('concurrent compiler builds', () => {
	const tempDirs = []

	afterEach(() => {
		for (const tempDir of tempDirs.splice(0)) {
			fs.rmSync(tempDir, { recursive: true, force: true })
		}
	})

	function createProject(name, appId, pagePath) {
		const projectDir = fs.mkdtempSync(path.join(os.tmpdir(), `compiler-${name}-`))
		tempDirs.push(projectDir)
		const write = (relativePath, content) => {
			const filePath = path.join(projectDir, relativePath)
			fs.mkdirSync(path.dirname(filePath), { recursive: true })
			fs.writeFileSync(filePath, content)
		}
		write('app.json', JSON.stringify({ pages: [pagePath] }))
		write('app.js', 'App({})\n')
		write('app.wxss', '')
		write('project.config.json', JSON.stringify({ appid: appId, projectname: name }))
		write(`${pagePath}.json`, '{}')
		write(`${pagePath}.js`, 'Page({})\n')
		write(`${pagePath}.wxml`, `<view>${name}</view>\n`)
		write(`${pagePath}.wxss`, '')
		return projectDir
	}

	it('keeps project metadata and outputs isolated', async () => {
		const firstProject = createProject('first-app', 'first-app-id', 'pages/first/index')
		const secondProject = createProject('second-app', 'second-app-id', 'pages/second/index')
		const firstOutput = path.join(firstProject, 'dist')
		const secondOutput = path.join(secondProject, 'dist')

		const [first, second] = await Promise.all([
			build(firstOutput, firstProject, false),
			build(secondOutput, secondProject, false),
		])

		expect(first).toMatchObject({ appId: 'first-app-id', name: 'first-app', path: 'pages/first/index' })
		expect(second).toMatchObject({ appId: 'second-app-id', name: 'second-app', path: 'pages/second/index' })
		expect(fs.readFileSync(path.join(firstOutput, 'main/app-config.json'), 'utf8')).toContain('pages/first/index')
		expect(fs.readFileSync(path.join(secondOutput, 'main/app-config.json'), 'utf8')).toContain('pages/second/index')
	})
})
