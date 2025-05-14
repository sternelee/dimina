import { resolve } from 'node:path'
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig(({ mode }) => {
	return {
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
				fileName: 'render',
			},
		},
		define: {
			__DEV__: mode !== 'production',
			__VUE_PROD_HYDRATION_MISMATCH_DETAILS__: false,
		},
		plugins: [vue()],
	}
})
