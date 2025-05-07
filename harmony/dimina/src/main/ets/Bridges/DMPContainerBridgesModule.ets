import { DMPApp } from '../DApp/DMPApp';
import { DMPMap } from '../Utils/DMPMap';
import { AppData, WorkerAppData } from '../Service/DMPSendableObjects';

import { DMPBridgeCallback, DMPBridgeCallbackType, isMainThread } from './DMPTSUtil';
import { DMPLogger } from '../EventTrack/DMPLogger';


export abstract class DMPContainerBridgesModule {
  app: DMPApp;
  appData: AppData;

  constructor(app: DMPApp);

  constructor(app: WorkerAppData);

  constructor(app: DMPApp | WorkerAppData) {
    if (isMainThread()) {
      this.app = app as DMPApp;
      this.appData = new AppData();
    } else {
      this.app = app as DMPApp;
      this.appData = JSON.parse(JSON.stringify(app))
    }
  }

  invokeSuccessCallback(callback: DMPBridgeCallback, param: DMPMap | undefined | null) {
    DMPLogger.d('invokeSuccessCallback', param?.toStr() ?? '')
    if (callback) {
      callback(param ? param : new DMPMap(), DMPBridgeCallbackType.Success)
    }
    this.invokeCompleteCallback(callback, null)
  }

  invokeFailureCallback(callback: DMPBridgeCallback, param: DMPMap | undefined | null, errMsg: string) {
    DMPLogger.d('invokeFailureCallback', param?.toStr() ?? '', errMsg)
    if (callback) {
      param = param || new DMPMap();
      param.set('data', {
        'errMsg': errMsg ?? 'failure'
      })
      callback(param, DMPBridgeCallbackType.Fail)
    }
    this.invokeCompleteCallback(callback, null)
  }

  abstract getExportMethods(): Array<string>;

  private invokeCompleteCallback(callback: DMPBridgeCallback, param: DMPMap | undefined | null) {
    DMPLogger.d('invokeCompleteCallback', param?.toStr() ?? '')
    if (callback) {
      callback(param ? param : new DMPMap(), DMPBridgeCallbackType.Complete)
    }
  }
}





