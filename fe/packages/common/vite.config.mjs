import { resolve } from 'node:path'
import { defineConfig } from 'vite'

export default defineConfig(({ mode }) => {
	return {
		resolve: {
			extensions: ['.js'],
			alias: {
				'@': resolve(__dirname, 'src'),
			},
		},
		build: {
			minify: mode === 'production' ? 'terser' : false,
			terserOptions: {
				compress: {
					pure_funcs: ['console.log'],
					drop_debugger: true,
					keep_fargs: false,
					reduce_vars: true,
					booleans: true,
				},
				format: {
					comments: false,
				},
			},
			lib: {
				entry: resolve(__dirname, 'src/index.js'),
				formats: ['es'],
				fileName: 'common',
			},
		},
	}
})
