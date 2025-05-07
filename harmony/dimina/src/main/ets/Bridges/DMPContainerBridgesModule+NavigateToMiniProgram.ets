import { DMPMap } from '../Utils/DMPMap';
import { DMPContainerBridgesModule } from './DMPContainerBridgesModule';

import { DMPBridgeCallback } from './DMPTSUtil';
import { promptAction } from '@kit.ArkUI';

export class DMPContainerBridgesModuleNavigateToMiniProgram extends DMPContainerBridgesModule {
  getExportMethods(): string[] {
    return ['navigateToMiniProgram'];
  }

  // 打开微信小程序，等待微信SDK接入
  navigateToMiniProgram(data: DMPMap, callback: DMPBridgeCallback) {
    promptAction.showToast({
      message: '暂不支持微信跳转',
      alignment: Alignment.Center
    })
  }
}