import { Tags } from '../EventTrack/Tags'
import { DMPLogger } from '../EventTrack/DMPLogger'
import { DMPContainerBridgesModule } from './DMPContainerBridgesModule'

import { DMPBridgeCallback } from './DMPTSUtil'
import { DMPMap } from '../Utils/DMPMap'
import { DMPChannelProxyNext } from '../Service/DMPChannelProxyNext'
import { DataTransformer } from '../Utils/DataTransformer'

export class DMPContainerBridgesModuleWeb extends DMPContainerBridgesModule {
  getExportMethods(): string[] {
    return [
      'postMessage',
      'propsUpdate',
      'componentMount',
      'componentUnmount',
      'adjustPosition'
    ];
  }

  postMessage(data: DMPMap, callback: DMPBridgeCallback, webViewId: number) {
    const subData: Map<string, object> = data.get('params')['data']
    const result = DataTransformer.eventContainerToWebView('bindWebviewPostMessage', subData, webViewId)
    DMPChannelProxyNext.ContainerToWebviewRender(result, this.app, webViewId)
  }

  propsUpdate(data: DMPMap, callback: DMPBridgeCallback, webViewId: number) {
    DMPLogger.d(Tags.BRIDGE, 'propsUpdate %{public}s', data.toStr())

    this.invokeSuccessCallback(callback, null)
  }

  componentMount(data: DMPMap, callback: DMPBridgeCallback, webViewId: number) {
    DMPLogger.d(Tags.BRIDGE, 'componentMount %{public}s', data.toStr())
    const stack = this.app.navigatorManager.getPageRecordById(webViewId)!
    stack.componentParams[data.get('id')] = data;
    this.invokeSuccessCallback(callback, null)
  }

  componentUnmount(data: DMPMap, callback: DMPBridgeCallback, webViewId: number) {
    DMPLogger.d(Tags.BRIDGE, 'componentUnmount %{public}s', data.toStr())
    const stack = this.app.navigatorManager.getPageRecordById(webViewId)!
    stack.componentParams[data.get('id')] = data;
    this.invokeSuccessCallback(callback, null)
  }

  adjustPosition(data: DMPMap, callback: DMPBridgeCallback, webViewId: number) {
    const bottom = data.getNumber('bottom')
    const pageRecord = this.app.navigatorManager.getPageRecordById(webViewId)
    if (pageRecord) {
      pageRecord.adjustPosition = bottom ?? 0
    }
    this.invokeSuccessCallback(callback, null)
  }
}
