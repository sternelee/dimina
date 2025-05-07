import { DMPLogger } from '../EventTrack/DMPLogger';
import { DMPContainerBridgesModule } from './DMPContainerBridgesModule';

import { DMPBridgeCallback } from './DMPTSUtil';

export class DMPContainerBridgesModuleAnalytics extends DMPContainerBridgesModule {
  getExportMethods(): string[] {
    return ['reportMiniProgram', 'reportAnalytics'];
  }

  reportMiniProgram(data: Array<Object>, callback: DMPBridgeCallback) {
    if (data.length > 0) {
      let event: string = data[0] as string;
      let params: object = new Object();
      if (data.length > 1) {
        params = data[1];
      }

      DMPLogger.d('reportMiniProgram', `event=${event} params=${JSON.stringify(params)}`);
    }
  }

  reportAnalytics(data: Array<Object>, callback: DMPBridgeCallback) {

  }
}