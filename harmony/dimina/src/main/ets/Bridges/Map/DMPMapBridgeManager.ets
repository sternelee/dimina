import { DMPWebViewController } from '../../HybridContainer/DMPWebViewController';
import { DMPApp } from '../../DApp/DMPApp';
import { DMPMap } from '../../Utils/DMPMap';
import { DMPBridgeCallback, DMPTSUtil } from '../DMPTSUtil';
import { DMPMapController } from './DMPMapController';

export class DMPMapManager {
  private app: DMPApp

  //缓存地图未初始化前要渲染的任务

  constructor(app: DMPApp) {
    this.app = app;
  }


  bind(webViewController: DMPWebViewController, map: DMPMapController) {
  }

  unBind(webViewController: DMPWebViewController) {

  }

  getMap(webViewController: DMPWebViewController): DMPMapController | null {
    return null;
  }

  getCurrentMap(app: DMPApp, webViewId: number): DMPMapController | null {

    return null;
  }

  executeLazyTask(webViewId: number) {

  }

  addLazyTask(task: CacheTask) {

  }
}

export interface CacheTask {
  method: string;
  params: DMPMap;
  callBack: DMPBridgeCallback;
  webViewId: number;

}