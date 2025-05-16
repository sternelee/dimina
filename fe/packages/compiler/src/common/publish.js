import path from 'node:path'
import process from 'node:process'
import shelljs from 'shelljs'
import { getAppId, getTargetPath } from '../env.js'

function createDist() {
	const distPath = getTargetPath()
	if (shelljs.test('-d', distPath)) {
		shelljs.rm('-rf', distPath)
	}
	shelljs.mkdir('-p', `${distPath}`)
}
/**
 * 发布到指定目录
 * @param {string} dist 目标路径
 * @param {boolean} useAppIdDir 是否在路径中包含appId
 */
function publishToDist(dist, useAppIdDir = true) {
	const distPath = getTargetPath()
	const appId = getAppId()
	const absolutePath = useAppIdDir
		? `${path.resolve(process.cwd(), dist)}/${appId}`
		: `${path.resolve(process.cwd(), dist)}`
	shelljs.rm('-rf', absolutePath)
	shelljs.mkdir('-p', absolutePath)
	shelljs.cp('-r', `${distPath}/*`, absolutePath)
}

export { createDist, publishToDist }
