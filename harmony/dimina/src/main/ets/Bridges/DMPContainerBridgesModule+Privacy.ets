import { DMPContainerBridgesModule } from './DMPContainerBridgesModule'

import { DMPBridgeCallback } from './DMPTSUtil'
import { DMPMap } from '../Utils/DMPMap';

export class DMPContainerBridgesModulePrivacy extends DMPContainerBridgesModule {
  getExportMethods(): string[] {
    return ['getPrivacySetting'];
  }

  getPrivacySetting(data: DMPMap, callback: DMPBridgeCallback) {
    const result = new DMPMap({ 'needAuthorization': false, 'privacyContractName': '《xxx隐私保护指引》' })
    this.invokeSuccessCallback(callback, result)
  }
}