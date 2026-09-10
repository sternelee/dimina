import { beforeEach, expect, it, vi } from 'vitest'
const { create, plugins } = vi.hoisted(() => ({ create: vi.fn(), plugins: [] as any[] }))
vi.mock('vconsole', () => {
	class Plugin {
		events: Record<string, any> = {}
		constructor(public id: string, public name: string) { plugins.push(this) }
		on(name: string, handler: any) { this.events[name] = handler; return this }
	}
	return { default: class {
		static VConsolePlugin = Plugin
		constructor() { create() }
		setSwitchPosition = vi.fn()
		addPlugin = vi.fn()
	} }
})
beforeEach(() => { vi.resetModules(); create.mockClear(); plugins.length = 0; delete window.vConsole; window.history.replaceState({}, '', '/') })
it('initializes synchronously with the native URL flag in production too', async () => {
	window.history.replaceState({}, '', '/?vconsole=1')
	await import('../src/pages/pageFrame/vconsole')
	expect(create).toHaveBeenCalledOnce(); expect(window.vConsole).toBeDefined()
	await window.__dimina_enable_vconsole__!(); expect(create).toHaveBeenCalledOnce()
})
it('does not create a console without explicit activation', async () => {
	await import('../src/pages/pageFrame/vconsole')
	expect(create).not.toHaveBeenCalled()
})
it('shows native storage values as text and allows refresh without browser storage writes', async () => {
	window.history.replaceState({}, '', '/?vconsole=1'); await import('../src/pages/pageFrame/vconsole')
	window.dispatchEvent(new Event('dimina:debug-ready'))
	const plugin = plugins.at(-1); let content: HTMLElement
	plugin.events.renderTab((element: HTMLElement) => { content = element })
	const request = vi.fn(); window.addEventListener('dimina:debug-storage-request', request)
	plugin.events.show(); expect(request).toHaveBeenCalledOnce()
	window.dispatchEvent(new CustomEvent('dimina:debug-storage', { detail: { value: [{ key: '<script>', data: 42 }] } }))
	expect(content!.textContent).toContain('<script>'); expect(content!.querySelector('script')).toBeNull()
	plugin.events.remove(); window.removeEventListener('dimina:debug-storage-request', request)
})
