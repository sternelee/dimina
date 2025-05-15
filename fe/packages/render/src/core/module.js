const TYPE_MAPS = {
	s: String,
	n: Number,
	b: Boolean,
	o: Object,
	a: Array,
	f: Function,
}

export class Module {
	constructor(moduleInfo) {
		this.moduleInfo = moduleInfo
	}

	setInitialData(props) {
		this.props = this.unSerializeProps(props)
	}

	unSerializeProps(properties) {
		if (!properties) {
			return
		}
		for (const key in properties) {
			const types = properties[key].type.map(item => this.convertStringToType(item))
			properties[key].type = types.length === 1 ? types[0] : types
		}

		return properties
	}

	/**
	 * 将字符串转换成实际类型
	 * @param {*} type
	 */
	convertStringToType(type) {
		if (type === null) {
			return null
		}
		const result = TYPE_MAPS[type]
		if (!result) {
			console.warn('[system]', '[render]', `unknown props type ${type}`)
		}
		return result
	}
}
