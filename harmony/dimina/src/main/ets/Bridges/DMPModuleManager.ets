import { DMPExportModule } from './DMPExportModule';
import { DMPContainerBridgesModule } from './DMPContainerBridgesModule';
import { DMPLogger } from '../EventTrack/DMPLogger';
import { Tags } from '../EventTrack/Tags';
import { DMPMap } from '../Utils/DMPMap';

export abstract class DMPModuleManager {
  abstract exportModules: Map<string, DMPExportModule>

  registerModule(moduleObject: DMPContainerBridgesModule) {
    this.registerModuleByName(moduleObject, 'DMPContainerBridgesModule')
  }

  registerWebViewModule(moduleObject: DMPContainerBridgesModule) {
    this.registerModuleByName(moduleObject, 'DMWebViewBridgeModule')
  }

  registerCustomModule(moduleObject: DMPContainerBridgesModule,moduleName?:string) {
    const name = moduleName || DMPMap.getClassName(moduleObject);
    this.registerModuleByName(moduleObject, name)
  }

  getModuleObjectByMethodName(methodName: string): DMPContainerBridgesModule | null {
    return this.getModuleObjectByMethodNameAndModuleName(methodName, 'DMPContainerBridgesModule')
  }

  getModuleObjectByMethodNameAndModuleName(methodName: string, moduleName: string): DMPContainerBridgesModule | null {
    if (!methodName || !moduleName) {
      return null
    }
    let result: DMPContainerBridgesModule | null = null
    const module = this.getExportModuleByName(moduleName)
    if (module) {
      const exportMethods = module.exportMethods
      result = exportMethods[methodName]
    }
    return result
  }

  getExportModuleByName(moduleName: string): DMPExportModule | null {
    if (!moduleName) {
      return null
    }
    return this.exportModules[moduleName]
  }

  private registerModuleByName(moduleObject: DMPContainerBridgesModule, moduleName: string) {
    DMPLogger.d(Tags.BRIDGE, "registerMethodsWithModuleName moduleName=" + moduleName)
    const methodList = moduleObject.getExportMethods()
    if (!methodList || !moduleObject) {
      return
    }
    DMPLogger.d(Tags.BRIDGE, "registerMethodsWithModuleName >" + methodList.toString())
    let module = this.getExportModuleByName(moduleName)
    if (!module) {
      module = new DMPExportModule(moduleName, moduleName)
      this.exportModules[moduleName] = module
    }
    if (module) {
      const exportMethods = module.exportMethods
      methodList.forEach((methodName) => {
        exportMethods[methodName] = moduleObject
      })
    }
  }
}






