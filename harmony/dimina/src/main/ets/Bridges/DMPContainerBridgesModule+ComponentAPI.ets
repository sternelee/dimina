import { DMPLogger } from '../EventTrack/DMPLogger';
import { DMPMap } from '../Utils/DMPMap';
import { DMPContainerBridgesModule } from './DMPContainerBridgesModule'

import { DMPBridgeCallback } from './DMPTSUtil'

export class DMPContainerBridgesModuleComponentAPI extends DMPContainerBridgesModule {
  getExportMethods(): string[] {
    return ['getSdkReportPoint'];
  }

  getSdkReportPoint(data: DMPMap, callback: DMPBridgeCallback) {
    DMPLogger.i('getSdkReportPoint')
  }
}


