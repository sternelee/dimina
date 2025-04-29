import fs from 'node:fs'
import {
	getAppConfigInfo,
	getPageConfigInfo,
	getTargetPath,
} from '../env.js'

/**
 *
 * 编译项目配置文件 app-config.json
 */
function compileConfig() {
	const compileResInfo = {
		app: getAppConfigInfo(),
		modules: getPageConfigInfo(),
	}

	const json = JSON.stringify(compileResInfo, null, 4)
	const mainDir = `${getTargetPath()}/main`
	if (!fs.existsSync(mainDir)) {
		fs.mkdirSync(mainDir)
	}
	fs.writeFileSync(`${mainDir}/app-config.json`, json)
}

export default compileConfig
