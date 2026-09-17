import { DMPMap } from '../Utils/DMPMap';
import { DMPContainerBridgesModule } from './DMPContainerBridgesModule';
import { DMPBridgeCallback } from './DMPTSUtil';

AppStorage.setOrCreate('loadingData', '加载中...')

export default class DMPContainerBridgesModuleLoading extends DMPContainerBridgesModule {
  getExportMethods(): string[] {
    return ['showLoading', 'hideLoading'];
  }

  showLoading(data: DMPMap, callback: DMPBridgeCallback | null, webViewId: number) {
    const record = this.app.navigatorManager.getPageRecordById(webViewId)
    if (!record) {
      if (callback) this.invokeFailureCallback(callback, null, 'showLoading:fail page not found')
      return
    }
    record.showLoadingTitle = data.get('title') ?? '加载中...'
    record.isShowLoading = true
    // Commit state before success so a callback can immediately call hideLoading.
    if (callback) this.invokeSuccessCallback(callback, new DMPMap({ 'errMsg': 'showLoading:ok' }))
  }

  hideLoading(_data: DMPMap, callback: DMPBridgeCallback | null, webViewId: number) {
    const record = this.app.navigatorManager.getPageRecordById(webViewId)
    if (!record) {
      if (callback) this.invokeFailureCallback(callback, null, 'hideLoading:fail page not found')
      return
    }
    record.isShowLoading = false
    if (callback) this.invokeSuccessCallback(callback, new DMPMap({ 'errMsg': 'hideLoading:ok' }))
  }
}
