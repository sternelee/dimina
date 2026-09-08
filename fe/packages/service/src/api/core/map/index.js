import { invokeAPI } from '@/api/common'
import router from '@/core/router'

export function createMapContext(mapId, obj) {
	return new MapContext({ mapId, obj })
}

class MapContext {
	constructor(opts) {
		this.opts = opts
		const page = router.getPageInfo()
		// A page's bridge ID routes the message; __id__ identifies its render module.
		this.bridgeId = opts.obj?.bridgeId || page?.bridgeId || page?.id
		this.moduleId = opts.obj?.__id__ || page?.__id__ || this.bridgeId
	}

	addMarkers(data) {
		return this.invoke('addMarkers', data)
	}

	removeMarkers(data) {
		return this.invoke('removeMarkers', data)
	}

	includePoints(data) {
		return this.invoke('includePoints', data)
	}

	setCenterOffset(data) {
		return this.invoke('setCenterOffset', data)
	}

	getCenterLocation(data) {
		return this.invoke('getCenterLocation', data)
	}

	getScale(data) {
		return this.invoke('getScale', data)
	}

	getRegion(data) {
		return this.invoke('getRegion', data)
	}

	moveToLocation(data) {
		return this.invoke('moveToLocation', data)
	}

	translateMarker(data) {
		return this.invoke('translateMarker', data)
	}

	addArc(data) {
		return this.invoke('addArc', data)
	}

	removeArc(data) {
		return this.invoke('removeArc', data)
	}

	invoke(apiName, data = {}) {
		return invokeAPI('mapContext', {
			...data,
			command: apiName,
			mapId: this.opts.mapId,
			moduleId: this.moduleId,
			mapBridgeId: this.bridgeId,
		}, 'render')
	}
}
