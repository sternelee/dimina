import { common, abilityAccessCtrl, Permissions } from '@kit.AbilityKit'
import { DMPNativeMapProvider, DMPNativeMapHandle, DMPNativeMapEvents, DMPMap } from '@didi-dimina/dimina'
import { AMapPrivacyAgreeStatus, AMapPrivacyInfoStatus, AMapPrivacyShowStatus } from '@amap/amap_lbs_common'
import { AMap, MapsInitializer, MapView, MapViewComponent, MapViewManager, MapViewCreateCallback,
  CameraUpdateFactory, CameraPosition, OnCameraChangeListener, LatLng, LatLngBounds, Marker, MarkerOptions } from '@amap/amap_lbs_map3d'

export class DMPAMapProvider implements DMPNativeMapProvider {
  private context: common.UIAbilityContext
  private apiKey: string
  private hasPrivacyConsent: () => boolean
  constructor(context: common.UIAbilityContext, apiKey: string, hasPrivacyConsent: () => boolean) {
    this.context = context; this.apiKey = apiKey; this.hasPrivacyConsent = hasPrivacyConsent
  }
  create(params: DMPMap, events: DMPNativeMapEvents): DMPNativeMapHandle {
    if (!this.hasPrivacyConsent()) throw new Error('Map privacy authorization denied')
    if (!this.apiKey) throw new Error('AMap HarmonyOS key is required')
    MapsInitializer.updatePrivacyShow(AMapPrivacyShowStatus.DidShow, AMapPrivacyInfoStatus.DidContain, this.context)
    MapsInitializer.updatePrivacyAgree(AMapPrivacyAgreeStatus.DidAgree, this.context)
    MapsInitializer.setApiKey(this.apiKey)
    MapsInitializer.initialize(this.context)
    return new AMapHandle(params, events, this.context)
  }
}
@Builder
function mapBuilder(params: DMPMap) {
  MapViewComponent({ mapViewName: params.getString('mapViewName') ?? '' }).width('100%').height('100%')
}
class AMapHandle implements DMPNativeMapHandle {
  builder: WrappedBuilder<[DMPMap]> = wrapBuilder(mapBuilder)
  builderParams: DMPMap
  private name: string
  private view?: MapView
  private map?: AMap
  private destroyed: boolean = false
  private props: DMPMap
  private previous: DMPMap = new DMPMap()
  private markers: Map<number, Marker> = new Map()
  private markerValues: Map<number, Object> = new Map()
  private lastCamera?: CameraPosition
  private initialized: boolean = false
  private createdCallback: MapViewCreateCallback
  private locationGeneration: number = 0
  private pendingLocation?: (point: LatLng) => void

  private events: DMPNativeMapEvents
  private context: common.UIAbilityContext
  private rejectLocation?: (error: Error) => void
  constructor(params: DMPMap, events: DMPNativeMapEvents, context: common.UIAbilityContext) {
    this.events = events; this.context = context
    this.name = params.getString('id') ?? ''
    this.props = new DMPMap(params.get('props'))
    this.builderParams = new DMPMap({ mapViewName: this.name })
    this.createdCallback = (view?: MapView, name?: string): void => {
      if (name !== this.name || !view || this.destroyed) return
      if (this.view) this.detach()
      this.view = view
      view.onCreate()
      view.onResume()
      view.getMapAsync((map: AMap) => {
        if (this.destroyed) return
        this.map = map
        this.bind(map)
        try {
          const markers = Array.from(this.markerValues.values())
          this.previous = new DMPMap()
          this.update(this.props)
          if (this.initialized) {
            if (this.lastCamera) map.moveCamera(CameraUpdateFactory.newCameraPosition(this.lastCamera))
            this.addMarkers(markers, true)
          }
          this.initialized = true
        } catch (error) { this.events.error((error as Error).message) }
      })
    }
    MapViewManager.getInstance().registerMapViewCreatedCallback(this.createdCallback)
  }
  private bind(map: AMap): void {
    map.setOnMapLoadedListener(() => { if (!this.destroyed) this.events.ready() })
    map.setOnMapClickListener((point: LatLng) => this.events.event('tap', coordinate(point)))
    map.setOnMarkerClickListener((marker: Marker): boolean => { this.markerEvent('markertap', marker); return false })
    map.setOnInfoWindowClickListener((marker: Marker) => this.markerEvent('callouttap', marker))
    let changing = false
    map.setOnCameraChangeListener(new OnCameraChangeListener(
      (position: CameraPosition) => { if (!changing) { changing = true; this.region('begin', position) } },
      (position: CameraPosition) => { changing = false; this.region('end', position) }))
    map.setOnMyLocationChangeListener(location => {
      if (this.destroyed) return
      const callback = this.pendingLocation
      this.pendingLocation = undefined
      this.rejectLocation = undefined
      callback?.(new LatLng(location.latitude, location.longitude))
      if (!this.props.getBoolean('showLocation')) map.setMyLocationEnabled(false)
    })
  }
  private markerEvent(type: string, marker: Marker): void {
    this.markers.forEach((value: Marker, id: number) => {
      if (value === marker) this.events.event(type, new DMPMap({ markerId: id }))
    })
  }
  private region(type: string, position: CameraPosition): void {
    this.events.event('regionchange', new DMPMap({ type: type, causedBy: 'update', centerLocation: coordinate(position.target).toJSON(), scale: position.zoom }))
  }
  update(props: DMPMap): void {
    if (this.destroyed) throw new Error('Map destroyed')
    this.props = props
    const map = this.map
    const changed = (key: string): boolean => JSON.stringify(props.get(key)) !== JSON.stringify(this.previous.get(key))
    if (!map) {
      if (changed('markers')) this.addMarkers(props.getArray<Object>('markers') ?? [], true)
      if (this.lastCamera) {
        this.lastCamera = new CameraPosition(
          changed('longitude') || changed('latitude') ? point(props) : this.lastCamera.target,
          changed('scale') ? props.getNumber('scale') ?? 16 : this.lastCamera.zoom,
          this.lastCamera.tilt, this.lastCamera.bearing)
      }
      this.previous = new DMPMap(JSON.parse(JSON.stringify(props.toJSON())))
      return
    }
    if (changed('longitude') || changed('latitude')) map.moveCamera(CameraUpdateFactory.newLatLng(point(props)))
    if (changed('scale')) map.moveCamera(CameraUpdateFactory.zoomTo(props.getNumber('scale') ?? 16))
    const settings = map.getUiSettings()
    settings?.setScrollGesturesEnabled(props.getBoolean('enableScroll') ?? true)
    settings?.setZoomGesturesEnabled(props.getBoolean('enableZoom') ?? true)
    settings?.setRotateGesturesEnabled(props.getBoolean('enableRotate') ?? false)
    settings?.setScaleControlsEnabled(props.getBoolean('showScale') ?? false)
    settings?.setCompassEnabled(props.getBoolean('showCompass') ?? false)
    settings?.setZoomControlsEnabled(false)
    if (changed('markers')) this.addMarkers(props.getArray<Object>('markers') ?? [], true)
    if (changed('includePoints')) {
      const points = props.getArray<Object>('includePoints') ?? []
      if (points.length > 0) this.fit(points, [])
    }
    if (changed('showLocation')) {
      const generation = ++this.locationGeneration
      if (props.getBoolean('showLocation')) this.authorizeLocation().then(allowed => {
        if (this.destroyed || generation !== this.locationGeneration) return
        if (allowed) map.setMyLocationEnabled(true)
        else this.events.error('Location permission denied')
      }).catch(() => this.events.error('Location permission request failed'))
      else map.setMyLocationEnabled(false)
    }
    this.previous = new DMPMap(JSON.parse(JSON.stringify(props.toJSON())))
  }
  private async authorizeLocation(): Promise<boolean> {
    const permissions: Permissions[] = ['ohos.permission.APPROXIMATELY_LOCATION', 'ohos.permission.LOCATION']
    const result = await abilityAccessCtrl.createAtManager().requestPermissionsFromUser(this.context, permissions)
    return result.authResults.some(value => value === 0)
  }
  async invoke(command: string, args: DMPMap): Promise<DMPMap> {
    const map = this.map
    if (!map || this.destroyed) throw new Error('Map is not ready')
    switch (command) {
      case 'getCenterLocation': {
        const position = map.getCameraPosition()
        if (!position) throw new Error('Map camera is not ready')
        return coordinate(position.target)
      }
      case 'getScale': return new DMPMap({ scale: map.getCameraPosition()?.zoom })
      case 'getRegion': {
        const bounds = map.getProjection()?.getVisibleRegion()?.latLngBounds
        if (!bounds) throw new Error('Map bounds are not ready')
        return new DMPMap({ southwest: coordinate(bounds.southwest).toJSON(), northeast: coordinate(bounds.northeast).toJSON() })
      }
      case 'moveToLocation': {
        let target: LatLng
        if (args.get('longitude') !== undefined || args.get('latitude') !== undefined) target = point(args)
        else {
          if (!await this.authorizeLocation()) throw new Error('Location permission denied')
          if (this.destroyed) throw new Error('Map destroyed')
          target = await new Promise<LatLng>((resolve, reject) => { this.pendingLocation = resolve; this.rejectLocation = reject; map.setMyLocationEnabled(true) })
        }
        if (this.destroyed) throw new Error('Map destroyed')
        map.moveCamera(CameraUpdateFactory.newLatLng(target))
        break
      }
      case 'addMarkers': {
        const markers = args.getArray<Object>('markers')
        if (!markers) throw new Error('Markers must be an array')
        this.addMarkers(markers, args.getBoolean('clear') ?? false)
        break
      }
      case 'removeMarkers': {
        const ids = args.getArray<number>('markerIds')
        if (!ids) throw new Error('markerIds must be an array')
        ids.forEach(id => { this.markers.get(id)?.remove(); this.markers.delete(id); this.markerValues.delete(id) })
        break
      }
      case 'includePoints': this.fit(args.getArray<Object>('points') ?? [], args.getArray<number>('padding') ?? []); break
      default: throw new Error(`AMap HarmonyOS provider does not support ${command}`)
    }
    return new DMPMap()
  }
  private addMarkers(values: Object[], clear: boolean): void {
    const options: Map<number, MarkerOptions> = new Map()
    values.forEach(value => {
      const item = new DMPMap(value)
      const id = item.getNumber('id')
      if (id === undefined || !Number.isInteger(id) || options.has(id)) throw new Error('Marker id must be a unique integer')
      options.set(id, new MarkerOptions().setPosition(point(item)).setTitle(item.getString('title') ?? '')
        .setSnippet(new DMPMap(item.get('callout')).getString('content') ?? '')
        .setRotateAngle(item.getNumber('rotate') ?? 0).setZIndex(item.getNumber('zIndex') ?? 0))
    })
    if (clear) { this.markers.forEach(marker => marker.remove()); this.markers.clear(); this.markerValues.clear() }
    values.forEach(value => { this.markerValues.set(new DMPMap(value).getNumber('id') ?? 0, value) })
    options.forEach((value, id) => {
      this.markers.get(id)?.remove()
      const marker = this.map?.addMarker(value)
      if (marker) this.markers.set(id, marker)
    })
  }
  private fit(values: Object[], padding: number[]): void {
    if (!values.length || (padding.length !== 0 && padding.length !== 4) || padding.some(n => !Number.isFinite(n) || n < 0)) throw new Error('Invalid points or padding')
    const bounds = LatLngBounds.builder()
    values.forEach(value => bounds.include(point(new DMPMap(value))))
    this.map?.moveCamera(CameraUpdateFactory.newLatLngBounds(bounds.build(), Math.max(0, ...padding)))
  }
  detach(): void {
    if (this.map) this.lastCamera = this.map.getCameraPosition()
    this.locationGeneration++
    this.pendingLocation = undefined
    this.rejectLocation?.(new Error('Map view detached'))
    this.rejectLocation = undefined
    this.map?.setMyLocationEnabled(false)
    this.view?.onPause()
    this.view?.onDestroy()
    this.markers.clear()
    this.map = undefined
    this.view = undefined
  }
  destroy(): void {
    if (this.destroyed) return
    this.destroyed = true
    MapViewManager.getInstance().unregisterMapViewCreatedCallback(this.createdCallback)
    this.detach()
    this.markerValues.clear()
  }
}
function point(value: DMPMap): LatLng {
  const longitude = value.getNumber('longitude')
  const latitude = value.getNumber('latitude')
  if (longitude === undefined || latitude === undefined || !Number.isFinite(longitude) || !Number.isFinite(latitude)
    || Math.abs(longitude) > 180 || Math.abs(latitude) > 90) throw new Error('Invalid coordinate')
  return new LatLng(latitude, longitude)
}
function coordinate(value: LatLng): DMPMap { return new DMPMap({ longitude: value.longitude, latitude: value.latitude }) }
