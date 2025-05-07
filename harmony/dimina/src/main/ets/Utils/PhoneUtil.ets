// import需要的模块
import call from '@ohos.telephony.call';
import { BusinessError } from '@ohos.base';
import { DMPLogger } from '../EventTrack/DMPLogger';

export class PhoneUtil{

  /**
   * 拨打电话的能力
   * @param phoneNum
   * @returns
   */
  public static callNum(phoneNum:string):Boolean{
    let isSupport = call.hasVoiceCapability();
    if(!isSupport)
      return false

    // 如果设备支持呼叫能力，则继续跳转到拨号界面，并显示拨号的号码
    call.makeCall(phoneNum, (err: BusinessError) => {
      if (!err) {
        DMPLogger.i("make call success.");
      } else {
        DMPLogger.i("make call fail, err is:" + JSON.stringify(err));
      }
    });
    // // 订阅通话业务状态变化（可选）
    // class SlotId {slotId: number = 0}
    // class CallStateCallback {
    //   state: call.CallState = call.CallState.CALL_STATE_UNKNOWN;
    //   number: string = "";
    // }
    // let slotId: SlotId = {slotId: 0}
    // observer.on("callStateChange", slotId, (data: CallStateCallback) => {
    //   console.log("call state change, data is:" + JSON.stringify(data));
    // });
    return false
  }

}
