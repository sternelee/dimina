import { DMPMap } from '../Utils/DMPMap'
import { DMPContainerBridgesModule } from './DMPContainerBridgesModule'

import { DMPBridgeCallback } from './DMPTSUtil'

export class DMPContainerBridgesModuleNavigateToMiniProgram extends DMPContainerBridgesModule {
  getExportMethods(): string[] {
    return ['navigateToMiniProgram']
  }

  // 跳微信小程序 等待微信sdk接入
  navigateToMiniProgram(data: DMPMap, callback: DMPBridgeCallback) {

  }
}

