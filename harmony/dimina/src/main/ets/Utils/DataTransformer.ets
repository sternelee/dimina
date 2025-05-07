import { DMPMap } from './DMPMap'

export class DataTransformer {
  public static transform(method: string, params: DMPMap): DMPMap {
    let result: DMPMap = new DMPMap()

    let payload: DMPMap = new DMPMap()
    payload.set('data', params)

    result.set('event', method)
    result.set('payload', payload)
    return result
  }


  public static decodeLoop(source: string): string {
    if (/%/.test(source)) {
      const newRes = decodeURIComponent(source)
      return DataTransformer.decodeLoop(newRes)
    }
    return source
  }

  static eventContainerToWebView(method: string, params: Map<string, object>, webViewId: number | undefined): DMPMap {
    const backDic = new DMPMap()
    const result = new DMPMap()
    result.set('data', params ?? {})
    if (webViewId && webViewId > 0) {
      result.set('webViewId', webViewId)
    }
    backDic.set('payload', result.toJSON())
    backDic.set('event', method)
    const msg: DMPMap = new DMPMap({
      type: 'triggerCallback',
      body: {
        args: backDic.toJSON()
      }
    })
    return msg
  }

  public static transformWithWebViewId(method: string, params: DMPMap, webViewId: number): DMPMap {
    let result: DMPMap = new DMPMap()

    let payload: DMPMap = new DMPMap()
    payload.set('data', params)
    payload.set('webViewId', webViewId)

    result.set('event', method)
    result.set('payload', payload)
    return result
  }

  static getPath(url: string): string {
    const parts = url.split('?');
    return parts[0];
  }


  static parse(url: string): DMPMap {
    const decodeUrl = url
    const firstIndex = decodeUrl.indexOf('?') > 0 ? decodeUrl.indexOf('?') : decodeUrl.length

    let pagePath = decodeUrl.slice(0, firstIndex);
    if (pagePath.startsWith('/') && pagePath.length > 0) {
      pagePath = pagePath.substring(1)
    }
    const paramStr = decodeUrl.slice(firstIndex + 1);
    const query = new DMPMap()
    const result = new DMPMap({ query, pagePath });
    const paramArray = paramStr.split('&')

    paramArray.forEach((param) => {
      const firstIndex = param.indexOf('=') > 0 ? param.indexOf('=') : param.length
      let key = param.slice(0, firstIndex);
      let value = param.slice(firstIndex + 1)
      const decodeValue = DataTransformer.decodeLoop(value)
      result.get('query').set(key, decodeValue)
    })
    return result;
  }
}