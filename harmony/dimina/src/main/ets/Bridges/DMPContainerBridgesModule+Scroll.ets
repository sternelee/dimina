import { DMPContainerBridgesModule } from './DMPContainerBridgesModule'

import { DMPBridgeCallback } from './DMPTSUtil'
import { DMPApp } from '../DApp/DMPApp';
import { DMPMap } from '../Utils/DMPMap';

export class DMPContainerBridgesModuleScroll extends DMPContainerBridgesModule {
  getExportMethods(): string[] {
    return ['pageScrollTo'];
  }

  pageScrollTo(data: DMPMap, callback: DMPBridgeCallback, webViewId: number) {
    const scrollTop: number = data.get('scrollTop') ?? 0
    const duration: number = data.get('duration') ?? 300 // 等华为提供新 api
    // 剩下的属性暂不开发，没有用到

    let app: DMPApp = this.app!
    const controller = app.render.getController(webViewId)

    controller.scrollTo(0, scrollTop);
    this.invokeSuccessCallback(callback, null)
  }
}