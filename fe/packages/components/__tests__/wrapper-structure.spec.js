import fs from 'node:fs'
import { fileURLToPath } from 'node:url'
import { describe, expect, it } from 'vitest'

const WRAPPER_FILE = fileURLToPath(new URL('../src/component/wrapper/Wrapper.vue', import.meta.url))

describe('Wrapper component structure', () => {
	it('keeps the custom component tag without creating a browser ShadowRoot', () => {
		const source = fs.readFileSync(WRAPPER_FILE, 'utf-8')

		expect(source).toContain('<component :is="componentName" v-bind="$attrs">')
		expect(source).not.toContain('attachShadow')
		expect(source).not.toContain('createShadowDOM')
		expect(source).not.toContain('wrapperRef')
	})
})
