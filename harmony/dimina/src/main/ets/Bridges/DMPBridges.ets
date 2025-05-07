import { DMPBridgeCallback, DMPBridgeCallbackType, DMPTSUtil } from './DMPTSUtil';

import { DMPMap } from '../Utils/DMPMap';
import { DMPChannelProxyNext } from '../Service/DMPChannelProxyNext';
import { DMPLogger } from '../EventTrack/DMPLogger';
import { Tags } from '../EventTrack/Tags';
import { DMPApp } from '../DApp/DMPApp';
import { DMPModuleManager } from './DMPModuleManager';

export class DMPBridges {
  static callWebViewMethods(methodName: string, webViewId: number,
    params: DMPMap | number | string | boolean | object, app: DMPApp): DMPMap | number | string | boolean | object {
    const callback: DMPBridgeCallback = (args: DMPMap, cbType: DMPBridgeCallbackType) => {
      if (params instanceof DMPMap) {
        let id = ''
        if (cbType == DMPBridgeCallbackType.Success) {
          if (!params.hasKey('success')) {
            return
          }
          id = params.get('success')
        } else if (cbType == DMPBridgeCallbackType.Fail) {
          if (!params.hasKey('fail')) {
            return
          }
          id = params.get('fail')
        } else if (cbType == DMPBridgeCallbackType.Complete) {
          if (!params.hasKey('complete')) {
            return
          }
          id = params.get('complete')
        }

        const msg: DMPMap = new DMPMap({
          type: 'triggerCallback',
          body: {
            id: id,
            args: {
              data: {
                success: cbType == DMPBridgeCallbackType.Success,
                data: args?.toObject() ?? new Object()
              }
            }
          }
        })

        DMPChannelProxyNext.ContainerToWebviewRender(msg, app, webViewId)
      }
    }

    // webview 部分的 bridge 暂时不接入 bridge
    const result = DMPBridges.invokeContainerMethodInfo(methodName, webViewId, params, callback, app.appModuleManager);
    return result;
  }

  static callMethodsNext(methodName: string, webViewId: number,
    params: DMPMap | number | string | boolean | object, appIndex: number,
    moduleManager: DMPModuleManager): number | string | boolean | object {
    const callback: DMPBridgeCallback = (args: DMPMap, cbType: DMPBridgeCallbackType) => {
      if (params instanceof DMPMap) {
        let id = ''
        if (cbType == DMPBridgeCallbackType.Success) {
          if (!params.hasKey('success')) {
            return
          }
          id = params.get('success')
        } else if (cbType == DMPBridgeCallbackType.Fail) {
          if (!params.hasKey('fail')) {
            return
          }
          id = params.get('fail')
        } else if (cbType == DMPBridgeCallbackType.Complete) {
          if (!params.hasKey('complete')) {
            return
          }
          id = params.get('complete')
        }

        const msg: DMPMap = new DMPMap({
          type: 'triggerCallback',
          body: {
            id: id,
            args: args?.toObject() ?? new Object()
          }
        })
        DMPChannelProxyNext.ContainerToService(msg, appIndex)
      }
    }
    const result = DMPBridges.invokeContainerMethodInfo(methodName, webViewId, params, callback, moduleManager)
    return result;
  }

  /*
  * moduleName：module名
  * methodName：方法名
  * params： 传递的参数，可以为null，null表示不传递参数
  * unfold：是否将参数展开调用,默认false  传参方式 true: ...params false: params
  * callback：回调，默认最后一个参数
  * */
  private static invokeContainerMethodInfo(methodName: string, webViewId: number,
    params: DMPMap | number | string | boolean | object, callback: DMPBridgeCallback,
    moduleManager: DMPModuleManager): number | string | boolean | object {
    let moduleName = 'DMPContainerBridgesModule';
    let invokeParams = params;
    if (params instanceof DMPMap && params.get('module')) {
      moduleName = params.get('module') as string
      if (moduleName === 'DMServiceBridgeModule' || moduleName === 'DMWebViewBridgeModule') {
        moduleName = 'DMPContainerBridgesModule';
      }
      invokeParams = DMPMap.createFromObject(params.get('data'))
    }
    DMPLogger.d(Tags.BRIDGE, `moduleName=${moduleName}   methodName=${methodName} `)
    let result: object = new Object();
    let obj = moduleManager?.getModuleObjectByMethodNameAndModuleName(methodName, moduleName)
    if (obj) {
      try {
        return DMPTSUtil.invokeNativeMethod(obj, methodName, invokeParams, webViewId, callback)
      } catch (err) {
        DMPLogger.e(Tags.BRIDGE, `Bridge invoke error  ${methodName}, ${moduleName}, ${err.toString()}`);
      }
    } else {
      DMPLogger.e(Tags.BRIDGE, `Bridge not implemented  ${methodName}, ${moduleName}`);
    }
    return result;
  }
}



