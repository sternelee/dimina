import { DMPLogger } from '../EventTrack/DMPLogger'
import { DMPMap } from '../Utils/DMPMap'
import { DMPContainerBridgesModule } from './DMPContainerBridgesModule'

import { DMPBridgeCallback } from './DMPTSUtil'

export class DMPContainerBridgesModuleBluetooth extends DMPContainerBridgesModule {
  getExportMethods(): string[] {
    return ['openBluetoothAdapter'];
  }

  openBluetoothAdapter(data: DMPMap, callback: DMPBridgeCallback) {
    DMPLogger.e('鸿蒙不支持 openBluetoothAdapter')
    this.invokeFailureCallback(callback, new DMPMap(), '鸿蒙不支持');
  }
}