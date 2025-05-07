import { DMPContainerBridgesModule } from '../DMPContainerBridgesModule'

import { DMPBridgeCallback } from '../DMPTSUtil'
import network from '@system.network';
import { DMPMap } from '../../Utils/DMPMap';

export class DMPContainerBridgesModuleNetwork extends DMPContainerBridgesModule {
  getExportMethods(): string[] {
    return ['getNetworkType'];
  }

  getNetworkType(_: DMPMap, callback: DMPBridgeCallback) {
    let result: DMPMap = new DMPMap()

    network.getType({
      success: (data) => {
        // 网络类型，可能的值有2g，3g，4g，5g，wifi，none等
        result.set('networkType', data.type.toLowerCase())
        this.invokeSuccessCallback(callback, result)
      }
    });
  }
}

