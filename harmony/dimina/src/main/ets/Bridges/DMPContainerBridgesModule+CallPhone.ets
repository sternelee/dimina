import { DMPLogger } from '../EventTrack/DMPLogger'
import { DMPMap } from '../Utils/DMPMap'
import { PhoneUtil } from '../Utils/PhoneUtil'
import { DMPContainerBridgesModule } from './DMPContainerBridgesModule'

import { DMPBridgeCallback } from './DMPTSUtil'

export class DMPContainerBridgesModuleCallPhone extends DMPContainerBridgesModule {
  getExportMethods(): string[] {
    return ['makePhoneCall'];
  }

  makePhoneCall(data: DMPMap, callback: DMPBridgeCallback) {
    const phoneNumber: string | undefined = data.getString('phoneNumber')

    DMPLogger.i(` makePhoneCall: ${phoneNumber}`)
    if (phoneNumber) {
      if (PhoneUtil.callNum(phoneNumber)) {
        this.invokeSuccessCallback(callback, null)
      } else {
        this.invokeFailureCallback(callback, null, "不支持拨打电话功能")
      }
    } else {
      this.invokeFailureCallback(callback, null, "未设置手机号")
    }
  }
}