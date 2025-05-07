import { DMPMap } from '../Utils/DMPMap';
import { DMPContainerBridgesModule } from './DMPContainerBridgesModule'

import { DMPBridgeCallback } from './DMPTSUtil'

export class DMPContainerBridgesModuleDom extends DMPContainerBridgesModule {
  getExportMethods(): string[] {
    return ['domReady', 'renderSuccess'];
  }

  domReady(data: DMPMap, callback: DMPBridgeCallback, webViewId: number) {
    this.invokeSuccessCallback(callback, null)
  }

  renderSuccess(data: DMPMap, callback: DMPBridgeCallback, webViewId: number) {
    this.invokeSuccessCallback(callback, null)
  }
}



