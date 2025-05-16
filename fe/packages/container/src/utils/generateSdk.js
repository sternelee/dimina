const process = require('node:process')
const path = require('node:path')
const fsExtra = require('fs-extra')
const archiver = require('archiver')

const sourceDir = './dist/assets/'
const mainDir = './jssdk/main/'
const targetDir = `${mainDir}assets/`
const sharedJssdkDir = path.resolve(__dirname, '../../../../../shared/jssdk/')

async function zipDirectory(sourceDir, outputFile) {
	const output = fsExtra.createWriteStream(outputFile)
	const archive = archiver('zip', {
		zlib: { level: 9 },
	})

	return new Promise((resolve, reject) => {
		output.on('close', () => {
			console.log('压缩成功')
			resolve()
		})

		archive.on('error', (err) => {
			reject(err)
		})

		archive.pipe(output)
		archive.directory(sourceDir, 'main')
		archive.finalize()
	})
}

async function updateConfigVersion() {
	const configPath = path.join(sharedJssdkDir, 'config.json')
	try {
		// 读取配置文件
		const config = await fsExtra.readJson(configPath)

		// 更新版本号
		config.versionCode += 1
		const versionParts = config.versionName.split('.')
		versionParts[2] = (Number.parseInt(versionParts[2]) + 1).toString()
		config.versionName = versionParts.join('.')

		// 写入更新后的配置
		await fsExtra.writeJson(configPath, config, { spaces: 2 })
		console.log(`配置版本已更新至 ${config.versionName} (${config.versionCode})`)
		return config
	}
	catch (err) {
		console.error('更新配置版本失败：', err)
		throw err
	}
}

async function generateSdk() {
	try {
		// 如果存在 main 目录，先删除
		await fsExtra.remove(mainDir)

		// 复制 assets 目录
		await fsExtra.copy(sourceDir, targetDir, {
			filter: src => !src.includes('index.'),
		})

		// 复制 pageFrame.html
		await fsExtra.copyFile('./dist/pageFrame.html', './jssdk/main/pageFrame.html')

		// 压缩目录
		await zipDirectory(mainDir, './jssdk/main.zip')

		// 更新配置版本
		const updatedConfig = await updateConfigVersion()

		// 复制 main.zip 到 shared/jssdk 目录
		await fsExtra.copy('./jssdk/main.zip', path.join(sharedJssdkDir, 'main.zip'))
		console.log(`已将 main.zip 复制到 ${sharedJssdkDir}`)

		console.log(`SDK 生成完成，版本 ${updatedConfig.versionName}`)
	}
	catch (err) {
		console.error('生成 SDK 过程中发生错误：', err)
		process.exit(1)
	}
}

generateSdk()
