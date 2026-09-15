import { debugRequest } from '../../../../core/debug'
import { invokeAPI } from '@/api/common'

function normalizeQuery(options) {
	if (!options || typeof options.url !== 'string') return options
	const method = (options.method || 'GET').toUpperCase()
	if (!['GET', 'HEAD', 'DELETE'].includes(method)
		|| Object.prototype.toString.call(options.data) !== '[object Object]') return options

	// Normalize once before the bridge so every host receives the same URL and no body.
	// Arrays use repeated keys; nullish fields and array items are omitted.
	const pairs = []
	for (const [key, value] of Object.entries(options.data)) {
		for (const item of Array.isArray(value) ? value : [value]) {
			if (item !== null && item !== undefined) {
				pairs.push(`${encodeURIComponent(key)}=${encodeURIComponent(String(item))}`)
			}
		}
	}

	let url = options.url
	if (pairs.length) {
		const hashIndex = url.indexOf('#')
		const fragment = hashIndex < 0 ? '' : url.slice(hashIndex)
		const base = hashIndex < 0 ? url : url.slice(0, hashIndex)
		const separator = base.includes('?') ? (/[?&]$/.test(base) ? '' : '&') : '?'
		url = `${base}${separator}${pairs.join('&')}${fragment}`
	}
	const normalized = { ...options, url, method }
	delete normalized.data
	return normalized
}

/**
 * 发起 HTTPS 网络请求
 * https://developers.weixin.qq.com/miniprogram/dev/api/network/request/wx.request.html
 * @param {*} opts
 */
export function request(opts) {
	return invokeAPI('request', debugRequest(normalizeQuery(opts)))
}
