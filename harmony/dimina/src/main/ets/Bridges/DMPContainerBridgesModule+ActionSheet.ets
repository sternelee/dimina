import { DMPMap } from '../Utils/DMPMap'
import { DMPContainerBridgesModule } from './DMPContainerBridgesModule'
import { DMPBridgeCallback } from './DMPTSUtil'

export class DMPContainerBridgesModuleActionSheet extends DMPContainerBridgesModule {
  getExportMethods(): string[] {
    return ['showActionSheet', 'show']
  }

  showActionSheet(data: DMPMap, callback: DMPBridgeCallback, webViewId: number) {
    const record = this.app.navigatorManager.getPageRecordById(webViewId)
    if (record && webViewId) {
      const title = data.getString('alertText')
      const color = data.getString('itemColor') ?? '#000000'
      const items = data.getArray<string>('itemList')
      if (record.actionSheetController != null) {
        record.actionSheetController.params = { title: title, color: color, items: items }
        record.actionSheetController.setOnSelectListener((index)=>{
          const result = new DMPMap()
          result.set('tapIndex',index)
          this.invokeSuccessCallback(callback,result);
        })
        record.actionSheetController.open()
      }
    }
  }

  show() {

  }
}


