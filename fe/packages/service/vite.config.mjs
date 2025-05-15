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
					drop_console: true,
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
				name: 'service', // 暴露的全局变量
				entry: resolve(__dirname, 'src/index.js'),
				formats: ['iife'],
			},
			rollupOptions: {
				output: {
					entryFileNames: 'service.js',
				},
			},
		},
	}
})
