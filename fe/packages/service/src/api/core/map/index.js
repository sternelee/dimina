import { invokeAPI } from '@/api/common'

export function createMapContext(mapId, obj) {
	return new MapContext({ mapId, obj })
}

class MapContext {
	constructor(opts) {
		this.opts = opts
	}

	addMarkers(data) {
		invokeAPI('addMarkers', data)
	}

	removeMarkers(data) {
		invokeAPI('removeMarkers', data)
	}

	includePoints(data) {
		invokeAPI('includePoints', data)
	}

	setCenterOffset(data) {
		invokeAPI('setCenterOffset', data)
	}

	getCenterLocation(data) {
		invokeAPI('getCenterLocation', data)
	}

	getScale(data) {
		invokeAPI('getScale', data)
	}

	moveToLocation(data) {
		invokeAPI('moveToLocation', data)
	}

	translateMarker(data) {
		invokeAPI('translateMarker', data)
	}

	addArc(data) {
		invokeAPI('addArc', data)
	}

	removeArc(data) {
		invokeAPI('removeArc', data)
	}
}
