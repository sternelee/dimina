import { DMPApp } from '../DApp/DMPApp';
import { DiminaPageString, monitorCoreEvent } from '../EventTrack/Monitor';
import { DMPMap } from '../Utils/DMPMap';
import { DMPContainerBridgesModule } from './DMPContainerBridgesModule'

import { DMPBridgeCallback } from './DMPTSUtil'

export class DMPContainerBridgesModuleLaunch extends DMPContainerBridgesModule {
  getExportMethods(): string[] {
    return ['invokeServiceReady', 'invokeBusinessReady', 'invokeWebViewReady',
      'getEnterOptionsSync', 'getLaunchOptionsSync', 'launch', 'initReady'];
  }

  invokeWebViewReady(data: DMPMap, callback: DMPBridgeCallback, webViewId: number) {
    this.invokeSuccessCallback(callback, null)
  }

  invokeServiceReady(data: DMPMap, callback: DMPBridgeCallback) {
    monitorCoreEvent(DiminaPageString.LAUNCH_INVOKE_SERVICE_READY, 'invokeServiceReady');
  }

  invokeBusinessReady(data: DMPMap, callback: DMPBridgeCallback) {
    monitorCoreEvent(DiminaPageString.LAUNCH_INVOKE_BUSINESS_READY, 'invokeBusinessReady')
    let app: DMPApp = this.app!;
    this.invokeSuccessCallback(callback, null)
  }

  launch(data: DMPMap, callback: DMPBridgeCallback) {

  }

  initReady(data: DMPMap, callback: DMPBridgeCallback) {

  }
}



