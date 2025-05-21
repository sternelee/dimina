import { resolve } from 'node:path'
import process from 'node:process'
import { defineConfig, loadEnv } from 'vite'
import { createHtmlPlugin } from 'vite-plugin-html'

export default defineConfig(({ mode }) => {
	const env = loadEnv(mode, process.cwd(), ['VITE_'])
	const enableHash = env.VITE_HASH === 'true'

	return {
		base: process.env.GITHUB_ACTIONS ? '/dimina/' : '/dimina',

		server: {
			open: true, // 启动后是否自动打开浏览器
		},
		define: {
			__DEV__: mode !== 'production',
		},
		resolve: {
			extensions: ['.js', '.scss'],
			alias: {
				'@': resolve(__dirname, 'src'),
				'@images': resolve(__dirname, '/images'),
			},
		},
		css: {
			preprocessorOptions: {
				scss: {
					additionalData: `@use "@/styles/funcs" as *;`,
				},
			},
		},
		optimizeDeps: {
			include: ['vconsole'],
		},
		build: {
			modulePreload: false,
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
			rollupOptions: {
				output: {
					// 设置入口文件（通常为主JavaScript文件）的命名规则
					entryFileNames: enableHash ? 'assets/[name]-[hash].js' : 'assets/[name].js',
					// 设置非入口 chunk（如按需加载的模块）的命名规则
					chunkFileNames: enableHash ? 'assets/[name]-[hash].js' : 'assets/[name].js',
					// 设置静态资源（如图片、字体等）的命名规则
					assetFileNames: enableHash ? 'assets/[name]-[hash][extname]' : 'assets/[name][extname]',
				},
			},
		},
		plugins: [
			createHtmlPlugin({
				minify: mode === 'production',
				viteNext: true,
				pages: [
					{
						entry: 'src/main.js',
						filename: 'index.html',
						template: 'index.html',
						injectOptions: {
							data: {
								// 提供默认值，避免环境变量未设置时出错
								dimina: env.VITE_TITLE || 'Dimina 小程序',
							},
						},
					},
					{
						entry: 'src/pages/pageFrame/pageFrame.js',
						filename: 'pageFrame.html',
						template: 'pageFrame.html',
						injectOptions: {
							data: {
								// 提供默认值，避免环境变量未设置时出错
								title: env.VITE_FRAME || 'Dimina Page Frame',
							},
						},
					},
				],
			}),
		],
	}
})
