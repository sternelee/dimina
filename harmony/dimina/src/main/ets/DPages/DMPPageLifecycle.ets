import { DMPApp } from '../DApp/DMPApp';
import { DMPChannelProxyNext } from '../Service/DMPChannelProxyNext';
import { DMPMap } from '../Utils/DMPMap';

export class DMPPageLifecycle {
  app: DMPApp

  constructor(app: DMPApp) {
    this.app = app;
  }


  // 新 FE 会调用，容器无需实现
  // static onLoad() {
  //
  // }

  onShow(webviewId: number) {
    const msg: DMPMap = new DMPMap({
      type: 'pageShow',
      body: {
        bridgeId: webviewId
      }
    })
    DMPChannelProxyNext.ContainerToService(msg, this.app.appIndex)
  }

  // 新 FE 会调用，容器无需实现
  // static onReady() {
  //
  // }

  onHide(webviewId: number) {
    if (webviewId <= 0) {
      return;
    }

    const msg: DMPMap = new DMPMap({
      type: 'pageHide',
      body: {
        bridgeId: webviewId
      }
    })
    DMPChannelProxyNext.ContainerToService(msg, this.app.appIndex)
  }

  onUnload(webviewId: number) {
    const msg: DMPMap = new DMPMap({
      type: 'pageUnload',
      body: {
        bridgeId: webviewId
      }
    })
    DMPChannelProxyNext.ContainerToService(msg, this.app.appIndex)
  }

  // 新 FE 暂未有这个 api
  // static onRouteDone() {
  //
  // }

}