import { callback, isFunction } from '@dimina/common'
import message from '../../core/message'
import router from '../../core/router'

export function invokeAPI(name, data, target = 'container') {
	let params
	if (data === undefined || typeof data === 'string' || Array.isArray(data)) {
		params = data
	}
	else {
		if (isFunction(data)) {
			params = {
				success: callback.store(data, true),
			}
		}
		else {
			const { success, fail, complete, keep, evtId, ...rest} = data

			params = rest

			if (isFunction(success)) {
				params.success = callback.store(success, keep, evtId)
			}
			else {
				params.success = success
			}

			if (isFunction(fail)) {
				params.fail = callback.store(fail, keep, evtId)
			}

			if (isFunction(complete)) {
				params.complete = callback.store(complete, keep, evtId)
			}
		}
	}

	const msg = {
		type: 'invokeAPI',
		target,
		body: {
			name,
			bridgeId: router.getPageInfo().id,
			params,
		},
	}
	if (target === 'container') {
		return message.invoke(msg)
	}
	else {
		return message.send(msg)
	}
}
