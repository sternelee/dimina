import { DMPMap } from '../Utils/DMPMap';
import { DMPContainerBridgesModule } from './DMPContainerBridgesModule';
import { DMPBridgeCallback } from './DMPTSUtil';
import { DialogManager } from './Widget/DialogManager';

export class DMPContainerBridgesModulePopUp extends DMPContainerBridgesModule {
  getExportMethods(): string[] {
    return ['showModal'];
  }

  showModal(data: DMPMap, callback: DMPBridgeCallback) {
    DialogManager.getInstance().showDialog({
      title: data.getString('title'),
      confirmText: data.getString('confirmText'),
      content: data.getString('content'),
      showCancel: data.getBoolean('showCancel') ?? true,
      cancelText: data.getString('cancelText') ?? '取消',
      cancelColor: data.getString('cancelColor') ?? "#000000",
      confirmColor: data.getString('confirmColor') ?? '#576B95',
      cancel: () => {
        this.invokeSuccessCallback(callback, new DMPMap({ "cancel": true }))
      },
      confirm: () => {
        this.invokeSuccessCallback(callback, new DMPMap({ "confirm": true }))
      }
    })
  }
}



