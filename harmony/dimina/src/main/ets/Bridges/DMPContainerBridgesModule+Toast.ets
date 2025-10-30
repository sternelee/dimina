import promptAction from '@ohos.promptAction';
import { DMPMap } from '../Utils/DMPMap';
import { DMPContainerBridgesModule } from './DMPContainerBridgesModule';
import { DMPBridgeCallback } from './DMPTSUtil';
import { BusinessError } from '@kit.BasicServicesKit';
import { deviceInfo } from '@kit.BasicServicesKit';

export class DMPContainerBridgesModuleToast extends DMPContainerBridgesModule {
  toastId: number = 0;

  getExportMethods(): string[] {
    return ['showToast', 'hideToast'];
  }

  showToast(data: DMPMap, callback: DMPBridgeCallback) {
    let duration: number = parseInt(data.get('duration')) / 1000.0;
    if (duration < 0 || duration > 1000) {
      duration = 1.5;
    }

    if (deviceInfo.sdkApiVersion >= 18) {
      promptAction.openToast({
        message: data.get('title'),
        duration: duration,
        alignment: Alignment.Center,
      }).then((toastId: number) => {
        this.toastId = toastId;
        this.invokeSuccessCallback(callback, null)
      }).catch((error: BusinessError) => {
        this.invokeFailureCallback(callback, null, error.message)
      })
    } else {
      promptAction.showToast({
        message: data.get('title'),
        duration: duration,
        alignment: Alignment.Center,
      })
      this.invokeSuccessCallback(callback, null)
    }
  }

  hideToast(_data: DMPMap, callback: DMPBridgeCallback) {
    if (deviceInfo.sdkApiVersion >= 18) {
      try {
        promptAction.closeToast(this.toastId);
        this.invokeSuccessCallback(callback, null)
      } catch (error) {
        this.invokeFailureCallback(callback, null, error.message)
      }
    }
  }
}


