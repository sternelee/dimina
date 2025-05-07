import { DMPMap } from '../Utils/DMPMap'
import { DMPContainerBridgesModule } from './DMPContainerBridgesModule'
import { DMPBridgeCallback } from './DMPTSUtil'
import { inputMethod } from '@kit.IMEKit';

export class DMPContainerBridgesModuleMisc extends DMPContainerBridgesModule {
  getExportMethods(): string[] {
    return ['canIUse', 'checkBridgeExist', 'hideKeyboard']
  }

  hideKeyboard(data: DMPMap, callback: DMPBridgeCallback){
    inputMethod.getController().stopInputSession();
    this.invokeSuccessCallback(callback, null)
  }

  canIUse(data: string, callback: DMPBridgeCallback) {
    const scheme: string = data
    const moduleManager = this.app?.appModuleManager
    const exportModules = moduleManager?.exportModules
    let result = false
    for (const key of Object.keys(exportModules!)) {
      const obj = moduleManager!
        .getModuleObjectByMethodNameAndModuleName(scheme, key)
      if (obj) {
        result = true
      }
    }
    return result
  }

  checkBridgeExist(data: DMPMap, callback: DMPBridgeCallback) {
    const isExist = this._checkBridgeExist(data)
    const result = new DMPMap()
    if (isExist) {
      result.set('bridgeExist', true)
    } else {
      result.set('bridgeExist', false)
    }
    this.invokeSuccessCallback(callback, result)
  }

  private _checkBridgeExist(data: DMPMap): boolean {
    const methodName = data.getString("methodName") ?? ''
    const moduleName = data.getString("moduleName") ?? 'DMPContainerBridgesModule'

    const appModuleManager = this.app?.appModuleManager;
    let appModule = appModuleManager?.getModuleObjectByMethodNameAndModuleName(methodName, moduleName)

    if (appModule) {
      appModule = appModuleManager!
        .getModuleObjectByMethodNameAndModuleName(methodName, moduleName)
      return true
    }

    const obj = appModuleManager!
      .getModuleObjectByMethodNameAndModuleName(data.getString("methodName") ?? "",
        data.getString("moduleName") ?? 'DMPContainerBridgesModule')

    if (obj) {
      return true
    }
    return false
  }
}

