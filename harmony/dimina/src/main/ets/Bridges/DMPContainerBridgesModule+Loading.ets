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
    if (record && webViewId) {
      record.isShowLoading = true;
      record.showLoadingTitle = data.get('title') || '加载中...'
    }

  }

  hideLoading(data: DMPMap, callback: DMPBridgeCallback | null, webViewId: number) {
    const record = this.app.navigatorManager.getPageRecordById(webViewId);
    if (record && webViewId) {
      record.isShowLoading = false;
    }
  }
}