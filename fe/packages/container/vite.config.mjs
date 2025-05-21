import { resolve } from 'node:path'
import process from 'node:process'
import { defineConfig, loadEnv } from 'vite'
import { createHtmlPlugin } from 'vite-plugin-html'

export default defineConfig(({ mode }) => {
	const env = loadEnv(mode, process.cwd(), ['VITE_'])
	const enableHash = env.VITE_HASH === 'true'

	// 从环境变量中获取 base path，或者使用默认值
	const basePath = process.env.VITE_BASE_PATH || '/'
	// 检测是否在 GitHub Actions 环境中运行
	const isGitHubActions = Boolean(process.env.GITHUB_ACTIONS)

	return {
		// 在 GitHub Actions 环境下使用 /dimina/ 作为 base path，否则使用环境变量或默认值
		base: isGitHubActions ? '/dimina/' : basePath,

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
								dimina: env.VITE_TITLE,
							},
						},
					},
					{
						entry: 'src/pages/pageFrame/pageFrame.js',
						filename: 'pageFrame.html',
						template: 'pageFrame.html',
						injectOptions: {
							data: {
								title: env.VITE_FRAME,
							},
						},
					},
				],
			}),
		],
	}
})
