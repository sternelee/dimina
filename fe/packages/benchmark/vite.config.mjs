import { fileURLToPath, URL } from 'node:url'
import { defineConfig } from 'vite'

export default defineConfig({
	root: fileURLToPath(new URL('./web', import.meta.url)),
	publicDir: fileURLToPath(new URL('./web/public', import.meta.url)),
	server: {
		host: '127.0.0.1',
		port: 5174,
		strictPort: true,
	},
	preview: {
		host: '127.0.0.1',
		port: 5174,
		strictPort: true,
	},
})
