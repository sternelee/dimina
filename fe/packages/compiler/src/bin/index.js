#!/usr/bin/env node

import process from 'node:process'
import path from 'node:path'
import { program } from 'commander'
import chokidar from 'chokidar'
import build from '../index.js'
import pack from '../../package.json'

program
	.command('build')
	.option('-c, --work-path <path>', '编译工作目录')
	.option('-s, --target-path <path>', '编译产物存放路径')
	.option('-w, --watch', '启用监听文件改动')
	.action(async (options) => {
		const workPath = options.workPath ? path.resolve(options.workPath) : process.cwd()
		const targetPath = options.targetPath ? path.resolve(options.targetPath) : process.cwd()

		await build(targetPath, workPath)
		const watch = options.watch
		if (watch) {
			chokidar
				.watch(workPath, {
					persistent: true, // 持续监听
					ignoreInitial: true, // 忽略初始的 add/addDir 事件
				})
				.on('all', async (event, path) => {
					if (event === 'change') {
						console.log(`${path} 改动，重新编译`)
						await build(targetPath, workPath)
					}
				})
		}
	})

program
	.name('dmcc')
	.version(pack.version)

program.parse(process.argv)
