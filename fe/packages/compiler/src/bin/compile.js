import fs from 'node:fs'
import path from 'node:path'
import process from 'node:process'
import build from '../index.js'

const CACHE_FILE = path.resolve('./packages/container/public/compile-cache.json')
const COMPILER_SRC_DIR = path.resolve('./packages/compiler/src')

function loadCache() {
	if (fs.existsSync(CACHE_FILE)) {
		try {
			return JSON.parse(fs.readFileSync(CACHE_FILE, 'utf8'))
		}
		catch {
			return { apps: {}, compilerLastModified: 0 }
		}
	}
	return { apps: {}, compilerLastModified: 0 }
}

function saveCache(cache) {
	fs.writeFileSync(CACHE_FILE, JSON.stringify(cache, null, 2))
}

function isModified(dirPath, lastCompileTime) {
	const files = fs.readdirSync(dirPath)
	for (const file of files) {
		const filePath = path.join(dirPath, file)
		const stats = fs.statSync(filePath)
		if (stats.isDirectory()) {
			if (isModified(filePath, lastCompileTime)) {
				return true
			}
		}
		else if (stats.mtime.getTime() > lastCompileTime) {
			return true
		}
	}
	return false
}

function isCompilerModified(lastCompileTime) {
	return isModified(COMPILER_SRC_DIR, lastCompileTime)
}

async function buildMiniApp() {
	const currentDirectory = `${process.cwd()}/example`
	const cache = loadCache()

	// 检查编译器是否被修改
	const compilerModified = isCompilerModified(cache.compilerLastModified)

	fs.readdir(currentDirectory, async (err, files) => {
		if (err) {
			console.error('无法读取目录:', err)
			return
		}

		const directories = files.filter(file => fs.statSync(path.join(currentDirectory, file)).isDirectory())

		const appList = []
		for (const fileName of directories) {
			const workPath = path.resolve(`./example/${fileName}`)
			const targetPath = path.resolve(workPath, '../../packages/container/public')

			const lastCompileTime = cache.apps[fileName]?.lastCompileTime || 0

			// 检查是否需要重新编译
			if (compilerModified || isModified(workPath, lastCompileTime)) {
				const appInfo = await build(targetPath, workPath)
				if (appInfo) {
					appList.push(appInfo)
					// 更新这个应用的最后编译时间
					cache.apps[fileName] = {
						lastCompileTime: Date.now(),
						appInfo,
					}
				}
			}
			else {
				// 如果没有修改，使用缓存中的appInfo
				if (cache.apps[fileName]?.appInfo) {
					appList.push(cache.apps[fileName].appInfo)
				}
			}
		}

		// 按修改时间降序
		appList.sort((a, b) => {
			const timeA = getLastCompileTime(cache, a.appId)
			const timeB = getLastCompileTime(cache, b.appId)
			return timeB - timeA
		})

		const appListString = JSON.stringify(appList, null, 2)
		fs.writeFileSync(path.resolve('./packages/container/public/appList.json'), appListString)

		// 更新编译器的最后修改时间
		cache.compilerLastModified = Date.now()

		// 保存更新后的缓存
		saveCache(cache)
	})
}

function getLastCompileTime(data, appId) {
	for (const key in data.apps) {
		if (data.apps[key].appInfo.appId === appId) {
			return data.apps[key].lastCompileTime
		}
	}
	return 0 // 如果找不到对应的 appId
}

buildMiniApp()
