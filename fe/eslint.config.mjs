// eslint.config.mjs
import antfu from '@antfu/eslint-config'
import { FlatCompat } from '@eslint/eslintrc'

const compat = new FlatCompat()

export default antfu({
	'stylistic': {
		indent: 'tab',
		quotes: 'single',
		semi: false,
	},
	'no-console': false,
	'typescript': false,
	'vue': true,
	'jsonc': false,
	'yaml': false,
	'ignores': ['example', 'packages/container/public', 'packages/container/dist'],
}, {
	rules: {
		'no-console': ['error', { allow: ['warn', 'error', 'log'] }],
		'vue/html-self-closing': ['error', {
			html: {
				void: 'always',
				normal: 'always',
				component: 'always',
			},
		}],
	},
},	...compat.config({
	globals: {
		__DEV__: 'readonly',
	},
	extends: './packages/components/.eslintrc-auto-import.json',
}))
