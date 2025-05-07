import { DMPMap } from '../Utils/DMPMap';
import { DMPContainerBridgesModule } from './DMPContainerBridgesModule';

import { DMPBridgeCallback } from './DMPTSUtil';
import pasteboard from '@ohos.pasteboard';
import systemDateTime from '@ohos.systemDateTime';
import { DMPLogger } from '../EventTrack/DMPLogger';
import { promptAction } from '@kit.ArkUI';
import { DMPContextUtils } from '../Utils/DMPContextUtils';
import { DMPPermissionUtils } from '../Utils/DMPPermissionUtils';

// TODO 功能实现待联调
export class DMPContainerBridgesModuleClipBoard extends DMPContainerBridgesModule {
  TAG: string = 'DMPContainerBridgesModuleClipBoard'
  mReadClipboardStartTime: number = 0

  getExportMethods(): string[] {
    return ['setClipboardData', 'getClipboardData', 'clearClipboard', 'readClipboardData'];
  }

  /**
   * 写剪切板
   * @param data
   * @param callback
   */
  setClipboardData(data: DMPMap, callback: DMPBridgeCallback) {
    let content: string | undefined = data.getString('data')
    let systemPasteboard: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard();
    if (content) { // 数据不为空覆盖
      let clip = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, content)
      systemPasteboard.setData(clip).then((res) => {
        const disableToast = data.getBoolean('disableToast')
        if (!disableToast) {
          promptAction.showToast({
            message: '内容已复制',
            alignment: Alignment.Center
          })
        }
        this.invokeSuccessCallback(callback, null)
        DMPLogger.i(`${this.TAG}  写剪切板成功-->${content}`)
      })
    } else { // 数据为空 清除
      this.invokeSuccessCallback(callback, null)
      systemPasteboard.clearData(() => {
        DMPLogger.i(`${this.TAG}  清楚剪切板成功-->${content}`)
      })
    }
  }

  /**
   * 读剪切板
   * @param data
   * @param callback
   */
  getClipboardData(data: DMPMap, callback: DMPBridgeCallback) {
    DMPPermissionUtils.checkPasteBoardPermissions(DMPContextUtils.getUIAbilityContext(), (result) => {
      if (result) {
        let systemPasteboard: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard();
        systemPasteboard.getData((err, res) => {
          if (err) {
            DMPLogger.e(`checkPermissions 读剪切板 失败-->${err.message}`)
            return;
          }
          let text = res.getPrimaryText()
          DMPLogger.d(`checkPermissions 读剪切板 成功-->${text}`)
          const result = new DMPMap();
          result.set('data', text ?? '')
          result.set('code', 0)
          this.invokeSuccessCallback(callback, result)
        })
      }
    });
  }

  /**
   * 清除剪切板
   * @param data
   * @param callback
   */
  clearClipboard(data: DMPMap, callback: DMPBridgeCallback) {
    this.setClipboardData(new DMPMap(), callback)
  }


  openClipboardAuth(data: DMPMap, callback: DMPBridgeCallback) {

  }

  /**
   * 一段时间内,限制重复获取剪切板
   *
   * @param data
   * @param callback
   */
  readClipboardData(data: DMPMap, callback: DMPBridgeCallback) {
    let validInterval: number | undefined = data.getNumber('validInterval')
    if (validInterval && (systemDateTime.getTime(false) - this.mReadClipboardStartTime) > validInterval) {
      this.getClipboardData(data, callback)
    } else {

    }
    this.mReadClipboardStartTime = systemDateTime.getTime(false)
  }


  /**
   * 读取是否有权限
   * @param data
   * @param callback
   */
  getClipboardState(data: DMPMap, callback: DMPBridgeCallback) {

  }
}