import { isFunction, uuid } from './utils'

class Callback {
	constructor() {
		this.callbacks = {}
	}

	store(callback, keep) {
		if (keep) {
			// 检查是否已经为该函数生成过 UUID
			for (const [k, v] of Object.entries(this.callbacks)) {
				if (v.callback === callback) {
					return k
				}
			}
		}

		const id = uuid()
		this.callbacks[id] = { callback, keep }
		return id
	}

	/**
	 * [Container] triggerCallback -> [Service] invoke
	 * @param {*} id
	 * @param {*} args
	 */
	invoke(id, args) {
		if (id === undefined) {
			return
		}
		const obj = this.callbacks[id]
		if (obj && isFunction(obj.callback)) {
			obj.callback(args)
			if (!obj.keep) {
				delete this.callbacks[id]
			}
		}
	}

	remove(id) {
		if (id) {
			Object.keys(this.callbacks).forEach((k) => {
				if (id === k) {
					delete this.callbacks[k]
				}
			})
		}
		else {
			Object.entries(this.callbacks).forEach(([k, v]) => {
				if (v.keep) {
					delete this.callbacks[k]
				}
			})
		}
	}
}

export default new Callback()
