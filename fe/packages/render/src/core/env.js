import loader from './loader'

class Env {
	constructor() {
		this.init()
	}

	init() {
		window.Module = moduleInfo => loader.createModule(moduleInfo)
	}
}

export default new Env()
