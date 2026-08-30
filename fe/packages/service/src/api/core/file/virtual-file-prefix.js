export const DEFAULT_VIRTUAL_FILE_PREFIX = 'difile://'
const RESERVED_VIRTUAL_FILE_SCHEMES = new Set([
	'about', 'blob', 'content', 'data', 'dimina', 'file', 'ftp', 'http', 'https',
	'internal', 'javascript', 'resource', 'ws', 'wss',
])

export function normalizeVirtualFilePrefix(value) {
	if (typeof value !== 'string') {
		throw new TypeError('virtualFilePrefix must be a string')
	}
	const normalized = value.trim().toLowerCase()
	const scheme = normalized.slice(0, -3)
	if (!/^[a-z][a-z0-9+.-]*:\/\/$/.test(normalized) || RESERVED_VIRTUAL_FILE_SCHEMES.has(scheme)) {
		throw new Error('virtualFilePrefix must be a custom URI scheme ending in "://"')
	}
	return normalized
}

/**
 * Native runtimes inject the value directly. Web Workers receive the same
 * per-container value through WorkerOptions.name before this bundle evaluates.
 */
export function resolveVirtualFilePrefix(scope = globalThis) {
	if (scope.__VIRTUAL_FILE_PREFIX__ !== undefined) {
		return normalizeVirtualFilePrefix(scope.__VIRTUAL_FILE_PREFIX__)
	}
	if (typeof scope.name === 'string' && scope.name) {
		try {
			const config = JSON.parse(scope.name)
			if (config && typeof config === 'object' && config.virtualFilePrefix !== undefined) {
				return normalizeVirtualFilePrefix(config.virtualFilePrefix)
			}
		}
		catch (error) {
			// A regular non-JSON Worker/window name is unrelated configuration.
			// Once valid JSON explicitly contains virtualFilePrefix, validation
			// errors must remain visible instead of silently using another scheme.
			if (error instanceof SyntaxError) return DEFAULT_VIRTUAL_FILE_PREFIX
			throw error
		}
	}
	return DEFAULT_VIRTUAL_FILE_PREFIX
}
