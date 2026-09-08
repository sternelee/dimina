import { loadAMap } from './amap-loader'

function point(value) {
	if (!value || typeof value.longitude !== 'number' || typeof value.latitude !== 'number'
		|| !Number.isFinite(value.longitude) || !Number.isFinite(value.latitude)
		|| Math.abs(value.longitude) > 180 || Math.abs(value.latitude) > 90) {
		throw new Error('invalid longitude or latitude')
	}
	return [value.longitude, value.latitude]
}
function coordinate(value) {
	return { longitude: value.getLng(), latitude: value.getLat() }
}
function number(value, fallback) {
	return typeof value === 'number' && Number.isFinite(value) ? value : fallback
}
function color(value) {
	const match = /^#([0-9a-f]{6})([0-9a-f]{2})$/i.exec(value)
	return match ? [`#${match[1]}`, Number.parseInt(match[2], 16) / 255] : [value, 1]
}
function textNode(doc, content) {
	const node = doc.createElement('div')
	node.textContent = String(content ?? '')
	return node
}

export async function createAMap({ element, props, emit, options: config, getLocation, signal }) {
	const AMap = await loadAMap(config, element.ownerDocument)
	if (signal.aborted) throw new Error('map destroyed')
	const map = new AMap.Map(element, {
		center: point(props), zoom: props.scale, viewMode: '2D',
		zooms: [props.minScale, props.maxScale],
	})
	let destroyed = false
	let previous = {}
	let locationRevision = 0
	let locationMarker
	let scaleControl
	let rejectReady
	const ready = new Promise((resolve, reject) => {
		rejectReady = reject
		map.on('complete', resolve)
	})
	ready.catch(() => {})
	const markers = new Map()
	const geometries = new Map()
	const listeners = []
	const on = (target, event, handler) => {
		target.on(event, handler)
		listeners.push(() => target.off(event, handler))
	}
	const destroy = () => {
		if (destroyed) return
		destroyed = true
		rejectReady(new Error('map destroyed'))
		locationRevision++
		listeners.splice(0).forEach(off => off())
		for (const entry of markers.values()) entry.dispose()
		markers.clear()
		map.destroy()
		signal.removeEventListener('abort', destroy)
	}
	signal.addEventListener('abort', destroy, { once: true })
	const assertActive = () => { if (destroyed) throw new Error('map destroyed') }
	const fire = (type, detail = {}) => { if (!destroyed) emit(type, detail) }

	function makeMarker(data) {
		const options = { position: point(data), title: data.title || '', angle: number(data.rotate, 0), zIndex: number(data.zIndex, 12) }
		if (data.iconPath) {
			const img = element.ownerDocument.createElement('img')
			img.src = data.iconPath
			img.style.width = `${number(data.width, 24)}px`
			img.style.height = `${number(data.height, 32)}px`
			options.content = img
		}
		const marker = new AMap.Marker(options)
		const markerId = data.id
		let callout
		let calloutNode
		const calloutTap = () => fire('callouttap', { markerId })
		if (data.callout?.content) {
			calloutNode = textNode(element.ownerDocument, data.callout.content)
			calloutNode.addEventListener('click', calloutTap)
			callout = new AMap.InfoWindow({ content: calloutNode })
		}
		const tap = () => {
			fire('markertap', { markerId })
			callout?.open(map, marker.getPosition())
		}
		marker.on('click', tap)
		return {
			marker,
			attach() {
				map.add(marker)
				if (data.callout?.display === 'ALWAYS') callout?.open(map, marker.getPosition())
			},
			dispose() {
				marker.off('click', tap)
				calloutNode?.removeEventListener('click', calloutTap)
				callout?.close()
				map.remove(marker)
			},
		}
	}
	function addMarkers(data, clear = false) {
		if (!Array.isArray(data)) throw new Error('markers must be an array')
		const next = new Map()
		try {
			for (const item of data) {
				if (!Number.isInteger(item.id) || next.has(item.id)) throw new Error('marker id must be a unique integer')
				next.set(item.id, makeMarker(item))
			}
		}
		catch (error) {
			for (const entry of next.values()) entry.dispose()
			throw error
		}
		if (clear) {
			for (const entry of markers.values()) entry.dispose()
			markers.clear()
		}
		for (const [id, entry] of next) {
			markers.get(id)?.dispose()
			markers.set(id, entry)
			entry.attach()
		}
	}
	function includePoints({ points, padding = [0, 0, 0, 0] }) {
		if (!Array.isArray(points) || points.length === 0) throw new Error('points must be a non-empty array')
		if (!Array.isArray(padding) || padding.length !== 4 || padding.some(n => !Number.isFinite(n) || n < 0)) {
			throw new Error('padding must contain four non-negative numbers')
		}
		const positions = points.map(point)
		const southwest = [Infinity, Infinity]
		const northeast = [-Infinity, -Infinity]
		for (const [longitude, latitude] of positions) {
			southwest[0] = Math.min(southwest[0], longitude)
			southwest[1] = Math.min(southwest[1], latitude)
			northeast[0] = Math.max(northeast[0], longitude)
			northeast[1] = Math.max(northeast[1], latitude)
		}
		// Fit coordinates directly, without relying on temporary marker geometry.
		// WeChat: top/right/bottom/left; AMap: top/bottom/left/right.
		const [zoom, center] = map.getFitZoomAndCenterByBounds(
			new AMap.Bounds(southwest, northeast), [padding[0], padding[2], padding[3], padding[1]],
		)
		map.setZoomAndCenter(zoom, center, true)
	}
	function replaceGeometry(type, data) {
		const next = []
		try {
			for (const item of data) {
				const [strokeColor, strokeOpacity] = color(item.color || item.strokeColor || '#000000')
				const [fillColor, fillOpacity] = color(item.fillColor || '#00000000')
				const options = { strokeColor, strokeOpacity, strokeWeight: number(item.width ?? item.strokeWidth, 1), fillColor, fillOpacity }
				if (type === 'circles') {
					if (!Number.isFinite(item.radius) || item.radius < 0) throw new Error('invalid circle radius')
					next.push(new AMap.Circle({ ...options, center: point(item), radius: item.radius }))
				}
				else {
					const path = item.points.map(point)
					const Constructor = type === 'polyline' ? AMap.Polyline : AMap.Polygon
					next.push(new Constructor({ ...options, path, strokeStyle: item.dottedLine ? 'dashed' : 'solid' }))
				}
			}
		}
		catch (error) { next.forEach(overlay => overlay.setMap(null)); throw error }
		map.remove(geometries.get(type) || [])
		map.add(next)
		geometries.set(type, next)
	}
	async function locate() {
		if (typeof getLocation !== 'function') throw new Error('host location provider is not configured')
		const location = await getLocation({ type: 'gcj02', signal })
		assertActive()
		return point(location)
	}
	async function showLocation(revision) {
		const position = await locate()
		if (revision !== locationRevision) return
		locationMarker?.setMap(null)
		locationMarker = new AMap.CircleMarker({ center: position, radius: 6, fillColor: '#1677ff', fillOpacity: 1, strokeColor: '#ffffff', strokeWeight: 2 })
		map.add(locationMarker)
	}
	function update(next) {
		assertActive()
		const changed = key => JSON.stringify(next[key]) !== JSON.stringify(previous[key])
		if (changed('longitude') || changed('latitude')) map.setCenter(point(next), true)
		if (changed('scale')) map.setZoom(number(next.scale, 16), true)
		if (changed('minScale') || changed('maxScale')) map.setZooms([number(next.minScale, 3), number(next.maxScale, 22)])
		map.setStatus({ dragEnable: next.enableScroll, zoomEnable: next.enableZoom, rotateEnable: next.enableRotate, pitchEnable: false })
		if (changed('rotate')) map.setRotation(number(next.rotate, 0), true)
		if (changed('markers')) addMarkers(next.markers || [], true)
		for (const type of ['polyline', 'polygons', 'circles']) if (changed(type)) replaceGeometry(type, next[type] || [])
		if (changed('includePoints') && next.includePoints?.length) includePoints({ points: next.includePoints })
		if (changed('showScale')) {
			if (next.showScale) { scaleControl = new AMap.Scale(); map.addControl(scaleControl) }
			else if (scaleControl) { map.removeControl(scaleControl); scaleControl = null }
		}
		if (changed('showLocation')) {
			const revision = ++locationRevision
			if (next.showLocation) showLocation(revision).catch(error => {
				if (revision === locationRevision) fire('error', { errMsg: `map:fail ${error.message}` })
			})
			else { locationMarker?.setMap(null); locationMarker = null }
		}
		previous = next
	}
	const methods = {
		getCenterLocation: () => coordinate(map.getCenter()),
		getScale: () => ({ scale: map.getZoom() }),
		getRegion: () => ({ southwest: coordinate(map.getBounds().getSouthWest()), northeast: coordinate(map.getBounds().getNorthEast()) }),
		addMarkers: data => addMarkers(data.markers, data.clear === true),
		removeMarkers(data) {
			if (!Array.isArray(data.markerIds)) throw new Error('markerIds must be an array')
			for (const id of data.markerIds) { markers.get(id)?.dispose(); markers.delete(id) }
		},
		includePoints,
		async moveToLocation(data) {
			const position = data.longitude === undefined && data.latitude === undefined ? await locate() : point(data)
			map.setCenter(position, true)
		},
	}
	try {
		on(map, 'click', event => fire('tap', coordinate(event.lnglat)))
		on(map, 'complete', () => { fire('updated'); fire('rendersuccess') })
		for (const event of ['movestart', 'moveend', 'zoomstart', 'zoomend']) {
			on(map, event, source => fire('regionchange', {
				type: event.endsWith('start') ? 'begin' : 'end',
				causedBy: source?.originEvent ? (event.startsWith('zoom') ? 'scale' : 'drag') : 'update',
				centerLocation: coordinate(map.getCenter()), scale: map.getZoom(),
			}))
		}
		update(props)
		await ready
	}
	catch (error) { destroy(); throw error }
	return {
		update, destroy,
		invoke(command, params) {
			assertActive()
			if (!Object.hasOwn(methods, command)) throw new Error(`AMap provider does not support ${command}`)
			return methods[command](params)
		},
	}
}
