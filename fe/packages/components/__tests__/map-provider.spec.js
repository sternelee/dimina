/** @vitest-environment jsdom */
import { createAMap } from '../src/component/map/providers/amap'
import { resolveMapProvider } from '../src/component/map/providers/registry'
import { loadAMap } from '../src/component/map/providers/amap-loader'

class EventTarget {
	constructor() { this.handlers = new Map() }
	on(type, handler) { if (!this.handlers.has(type)) this.handlers.set(type, new Set()); this.handlers.get(type).add(handler) }
	off(type, handler) { this.handlers.get(type)?.delete(handler) }
	emit(type, value) { this.handlers.get(type)?.forEach(handler => handler(value)) }
}
function coordinate([longitude, latitude]) { return { getLng: () => longitude, getLat: () => latitude } }
function sdk() {
	const maps = []
	const windows = []
	class MapSDK extends EventTarget {
		constructor(element, options) {
			super(); this.options = options; this.center = options.center; this.zoom = options.zoom
			this.add = vi.fn()
			this.remove = vi.fn()
			this.destroy = vi.fn()
			this.getFitZoomAndCenterByBounds = vi.fn(() => [12, coordinate([2, 3])])
			this.setZoomAndCenter = vi.fn()
			this.setCenter = vi.fn(center => { this.center = center })
			this.setZoom = vi.fn(zoom => { this.zoom = zoom })
			this.setZooms = vi.fn(); this.setStatus = vi.fn(); this.setRotation = vi.fn()
			this.addControl = vi.fn(); this.removeControl = vi.fn()
			maps.push(this)
			queueMicrotask(() => this.emit('complete'))
		}
		getCenter() { return coordinate(this.center) }
		getZoom() { return this.zoom }
	}
	class Overlay extends EventTarget {
		constructor(options) { super(); this.options = options; this.setMap = vi.fn() }
		getPosition() { return coordinate(this.options.position) }
	}
	class InfoWindow {
		constructor(options) { this.options = options; this.open = vi.fn(); this.close = vi.fn(); windows.push(this) }
	}
	class Bounds {
		constructor(southwest, northeast) { this.southwest = southwest; this.northeast = northeast }
	}
	return { maps, windows, AMap: { Map: MapSDK, Bounds, Marker: Overlay, Circle: Overlay, CircleMarker: Overlay, Polyline: Overlay, Polygon: Overlay, InfoWindow, Scale: class {} } }
}
const base = { longitude: 116.4, latitude: 39.9, scale: 16, minScale: 3, maxScale: 22, enableScroll: true, enableZoom: true, markers: [], polyline: [], circles: [], polygons: [], includePoints: [], showLocation: false, showScale: false }
const fixtures = []
async function fixture(props = {}, getLocation) {
	const mock = sdk()
	const emit = vi.fn()
	const controller = new AbortController()
	const adapter = await createAMap({ element: document.createElement('div'), props: { ...base, ...props }, options: { AMap: mock.AMap }, signal: controller.signal, emit, getLocation })
	fixtures.push(adapter)
	return { ...mock, adapter, emit, controller, map: mock.maps[0] }
}
afterEach(() => { fixtures.splice(0).forEach(adapter => adapter.destroy()); vi.useRealTimers() })

it('selects an external provider with isolated options and preserves its this', () => {
	const provider = { value: 42, create() { return this.value } }
	const result = resolveMapProvider({ provider: 'tencent', providers: { tencent: provider }, providerOptions: { tencent: { key: 'public-web-key' }, amap: { key: 'other' } } })
	expect(result.create()).toBe(42)
	expect(result.options).toEqual({ key: 'public-web-key' })
	expect(() => resolveMapProvider({ provider: 'missing' })).toThrow('not registered')
	expect(() => resolveMapProvider({ provider: 'toString' })).toThrow('not registered')
})
it('creates a map, emits readiness, and forwards taps as coordinates', async () => {
	const { adapter, map, emit } = await fixture()
	expect(adapter.invoke('getCenterLocation', {})).toEqual({ longitude: 116.4, latitude: 39.9 })
	map.emit('click', { lnglat: coordinate([116, 39]) })
	expect(emit).toHaveBeenCalledWith('tap', { longitude: 116, latitude: 39 })
	expect(emit).toHaveBeenCalledWith('rendersuccess', {})
})
it('preserves imperative center, zoom and markers when unrelated props change', async () => {
	const { adapter, map } = await fixture()
	await adapter.invoke('moveToLocation', { longitude: 0, latitude: 0 })
	adapter.invoke('addMarkers', { markers: [{ id: 0, longitude: 0, latitude: 0 }] })
	map.setZoom(18)
	map.setCenter.mockClear(); map.setZoom.mockClear(); map.remove.mockClear()
	adapter.update({ ...base, showScale: true })
	expect(map.setCenter).not.toHaveBeenCalled()
	expect(map.setZoom).not.toHaveBeenCalled()
	expect(map.remove).not.toHaveBeenCalled()
	expect(adapter.invoke('getCenterLocation', {})).toEqual({ longitude: 0, latitude: 0 })
})
it('maps marker ID 0, replaces IDs and removes listeners with removed markers', async () => {
	const { adapter, map, emit } = await fixture({ markers: [{ id: 0, longitude: 1, latitude: 2 }] })
	const first = map.add.mock.calls.find(([item]) => !Array.isArray(item))[0]
	first.emit('click')
	expect(emit).toHaveBeenCalledWith('markertap', { markerId: 0 })
	adapter.invoke('addMarkers', { markers: [{ id: 0, longitude: 2, latitude: 3 }] })
	emit.mockClear(); first.emit('click')
	expect(emit).not.toHaveBeenCalled()
	expect(map.remove).toHaveBeenCalledWith(first)
})
it('rejects invalid replacement data without clearing existing markers', async () => {
	const { adapter, map } = await fixture({ markers: [{ id: 1, longitude: 1, latitude: 2 }] })
	map.remove.mockClear()
	expect(() => adapter.invoke('addMarkers', { clear: true, markers: [{ id: 2, longitude: 200, latitude: 0 }] })).toThrow('invalid')
	expect(map.remove).not.toHaveBeenCalled()
})
it('fits only supplied points and translates padding order', async () => {
	const { adapter, map } = await fixture()
	map.add.mockClear(); map.remove.mockClear()
	adapter.invoke('includePoints', { points: [{ longitude: 3, latitude: 2 }, { longitude: 1, latitude: 4 }], padding: [1, 2, 3, 4] })
	const [bounds, padding] = map.getFitZoomAndCenterByBounds.mock.calls[0]
	expect(bounds.southwest).toEqual([1, 2])
	expect(bounds.northeast).toEqual([3, 4])
	expect(padding).toEqual([1, 3, 4, 2])
	expect(map.setZoomAndCenter).toHaveBeenCalledWith(12, map.getFitZoomAndCenterByBounds.mock.results[0].value[1], true)
	expect(map.add).not.toHaveBeenCalled()
	expect(map.remove).not.toHaveBeenCalled()
})
it('does not request location for display or explicit movement', async () => {
	const getLocation = vi.fn(async () => ({ longitude: 1, latitude: 2 }))
	const { adapter } = await fixture({}, getLocation)
	await adapter.invoke('moveToLocation', { longitude: 0, latitude: 0 })
	expect(getLocation).not.toHaveBeenCalled()
	await adapter.invoke('moveToLocation', {})
	expect(getLocation).toHaveBeenCalledTimes(1)
})
it('ignores a late location result after show-location is disabled', async () => {
	let resolve
	const getLocation = () => new Promise(r => { resolve = r })
	const { adapter, map } = await fixture({ showLocation: true }, getLocation)
	adapter.update({ ...base, showLocation: false })
	map.add.mockClear()
	resolve({ longitude: 1, latitude: 2 })
	await Promise.resolve(); await Promise.resolve()
	expect(map.add).not.toHaveBeenCalled()
})
it('rejects unsupported commands and prevents late location mutation after teardown', async () => {
	let resolve
	const { adapter, map, controller } = await fixture({}, () => new Promise(r => { resolve = r }))
	expect(() => adapter.invoke('addArc', {})).toThrow('does not support')
	const pending = adapter.invoke('moveToLocation', {})
	controller.abort(); adapter.destroy()
	map.setCenter.mockClear()
	resolve({ longitude: 1, latitude: 2 })
	await expect(pending).rejects.toThrow('destroyed')
	expect(map.setCenter).not.toHaveBeenCalled()
	expect(map.destroy).toHaveBeenCalledTimes(1)
})
it('treats callout text as text, not executable HTML', async () => {
	const { windows } = await fixture({ markers: [{ id: 1, longitude: 1, latitude: 2, callout: { content: '<img src=x onerror=alert(1)>' } }] })
	expect(windows[0].options.content.textContent).toBe('<img src=x onerror=alert(1)>')
	expect(windows[0].options.content.children).toHaveLength(0)
})
it('loads AMap once per document and rejects a conflicting key', async () => {
	const frame = document.createElement('iframe'); document.body.append(frame)
	const doc = frame.contentDocument
	const first = loadAMap({ key: 'public-a', serviceHost: 'https://maps.example.test/_AMapService' }, doc)
	const second = loadAMap({ key: 'public-a', serviceHost: 'https://maps.example.test/_AMapService' }, doc)
	expect(first).toBe(second)
	expect(doc.querySelectorAll('script')).toHaveLength(1)
	await expect(loadAMap({ key: 'public-b' }, doc)).rejects.toThrow('conflicting')
	doc.defaultView.AMap = {}
	doc.querySelector('script').dispatchEvent(new Event('load'))
	await first
	frame.remove()
})
it('reports a script error without exposing key-bearing URLs', async () => {
	const frame = document.createElement('iframe'); document.body.append(frame)
	const doc = frame.contentDocument
	const pending = loadAMap({ key: 'public-a' }, doc)
	doc.querySelector('script').dispatchEvent(new Event('error'))
	await expect(pending).rejects.toThrow('AMap script load failed')
	frame.remove()
})

it('maps RGBA geometry colors to SDK color and opacity fields', async () => {
	const { map } = await fixture({ circles: [{ longitude: 116, latitude: 39, radius: 100, color: '#ff000080', fillColor: '#00000000' }] })
	const circle = map.add.mock.calls.flatMap(([value]) => Array.isArray(value) ? value : [value]).find(value => value.options.radius === 100)
	expect(circle.options).toMatchObject({ strokeColor: '#ff0000', fillColor: '#000000', fillOpacity: 0 })
	expect(circle.options.strokeOpacity).toBeCloseTo(128 / 255)
})
