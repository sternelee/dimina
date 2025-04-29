const process = require('node:process')
const { exec } = require('node:child_process')
const fsExtra = require('fs-extra')
const archiver = require('archiver')

const sourceDir = './dist/assets/'
const mainDir = './jssdk/main/'
const targetDir = `${mainDir}assets/`

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

		console.log('SDK 生成完成')

		// 打开目标目录
		exec('open ./jssdk', (error) => {
			if (error) {
				console.error('打开目录失败：', error)
				return
			}
			console.log('已打开目标目录')
		})
	}
	catch (err) {
		console.error('生成 SDK 过程中发生错误：', err)
		process.exit(1)
	}
}

generateSdk()
