import { resolve } from 'node:path'
import vue from '@vitejs/plugin-vue'
import ViteAutoImport from 'unplugin-auto-import/vite'
import { defineConfig } from 'vite'

export default defineConfig(({ mode }) => {
	return {
		resolve: {
			extensions: ['.js', '.scss'],
			alias: {
				'@': resolve(__dirname, 'src'),
				'@component': resolve(__dirname, 'src/component'),
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
				entry: resolve(__dirname, 'index.js'),
				formats: ['es'],
				fileName: 'components',
			},
			rollupOptions: {
				external: ['vue'],
				output: {
					globals: {
						vue: 'vue',
					},
				},
			},
		},
		plugins: [
			vue(),
			ViteAutoImport({
				eslintrc: {
					enabled: true,
				},
				imports: ['vue'],
			}),
		],
	}
})
