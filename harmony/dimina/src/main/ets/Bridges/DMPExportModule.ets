import { DMPContainerBridgesModule } from './DMPContainerBridgesModule'

export class DMPExportModule {
  moduleName: string
  clsName: string
  exportMethods: Map<string, DMPContainerBridgesModule>

  constructor(moduleName: string, clsName: string) {
    this.moduleName = moduleName
    this.clsName = clsName
    this.exportMethods = new Map()
  }
}