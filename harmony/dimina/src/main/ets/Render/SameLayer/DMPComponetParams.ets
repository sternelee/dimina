export class VideoParams {
  appIndex?: number
  src: string | undefined
  duration: number | undefined
  controls: string | undefined
  width: number | undefined
  height: number | undefined
  parentWebViewId?: number
}


export class CameraParams {
  appIndex?: number
  textOne: string | undefined
  textTwo: string | undefined
  width: number | undefined
  height: number | undefined
  parentWebViewId?: number
}

export class MapParams {
  appIndex?: number
  id?: string
  longitude: string | undefined
  latitude: string | undefined
  scale: string | undefined
  markers?: Array<object>
  polyline?: Array<object>
  polygons?: Array<object>
  circles: string | undefined
  width: number | undefined
  height: number | undefined
  includePoints?: Array<object>
  showLocation?: string
  parentWebViewId?: number
}

export class WebViewParams {
  appIndex?: number
  parentWebViewId?: number
  width: number | undefined
  height: number | undefined
  attributes?: Attributes
  id?: string
  type?: string
  url?: string
}

export class Attributes {
  src?: string
  javascript?: string
  attrs?: object
  moduleId?: string
}
