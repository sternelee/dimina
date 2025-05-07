import promptAction from '@ohos.promptAction';
import { DMPMap } from '../Utils/DMPMap';

import { DMPContainerBridgesModule } from './DMPContainerBridgesModule';

import { DMPBridgeCallback } from './DMPTSUtil';

export class DMPContainerBridgesModuleToast extends DMPContainerBridgesModule {
  getExportMethods(): string[] {
    return ['showToast', 'hideToast'];
  }

  showToast(data: DMPMap, callback: DMPBridgeCallback) {
    let duration: number = parseInt(data.get('duration')) / 1000.0;
    if (duration < 0 || duration > 1000) {
      duration = 1.5;
    }

    promptAction.showToast({
      message: data.get('title'),
      duration: duration,
      alignment: Alignment.Center,
    })
    this.invokeSuccessCallback(callback, null)
  }


  hideToast() {

  }


}


