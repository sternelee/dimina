import { DMPApp } from '../DApp/DMPApp';
import { DMPChannelProxyNext } from '../Service/DMPChannelProxyNext';
import { DMPMap } from '../Utils/DMPMap';

export class DMPPageLifecycle {
  app: DMPApp

  constructor(app: DMPApp) {
    this.app = app;
  }

  onShow(webviewId: number) {
    const msg: DMPMap = new DMPMap({
      type: 'pageShow',
      body: {
        bridgeId: webviewId
      }
    })
    DMPChannelProxyNext.ContainerToService(msg, this.app.appIndex)
  }

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


}