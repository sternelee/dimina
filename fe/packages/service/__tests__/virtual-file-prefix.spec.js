import { describe, expect, it } from 'vitest'
import {
	DEFAULT_VIRTUAL_FILE_PREFIX,
	normalizeVirtualFilePrefix,
	resolveVirtualFilePrefix,
} from '../src/api/core/file/virtual-file-prefix.js'

describe('virtual file prefix configuration', () => {
	it('prefers native injection over Worker name configuration', () => {
		expect(resolveVirtualFilePrefix({
			__VIRTUAL_FILE_PREFIX__: 'NativeFile://',
			name: JSON.stringify({ virtualFilePrefix: 'worker-file://' }),
		})).toBe('nativefile://')
	})

	it('reads the prefix from the Web Worker startup configuration', () => {
		expect(resolveVirtualFilePrefix({
			name: JSON.stringify({ virtualFilePrefix: 'host-file://' }),
		})).toBe('host-file://')
	})

	it('keeps the default for unrelated Worker names', () => {
		expect(resolveVirtualFilePrefix({ name: 'host-worker' })).toBe(DEFAULT_VIRTUAL_FILE_PREFIX)
	})

	it('rejects prefixes that include a path or omit the scheme delimiter', () => {
		expect(() => normalizeVirtualFilePrefix('host-file://usr/')).toThrow()
		expect(() => normalizeVirtualFilePrefix('host-file')).toThrow()
		expect(() => normalizeVirtualFilePrefix('https://')).toThrow()
	})
})
