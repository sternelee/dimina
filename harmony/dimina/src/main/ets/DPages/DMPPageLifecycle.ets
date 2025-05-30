import { DMPApp } from '../DApp/DMPApp';
import { DMPLogger } from '../EventTrack/DMPLogger';
import { Tags } from '../EventTrack/Tags';
import { DMPChannelProxyNext } from '../Service/DMPChannelProxyNext';
import { DMPMap } from '../Utils/DMPMap';

export class DMPPageLifecycle {
  app: DMPApp

  constructor(app: DMPApp) {
    this.app = app;
  }

  onShow(webviewId: number) {
    DMPLogger.i(Tags.ON_PAGE_SHOW, `webviewId:${webviewId}`)
    const msg: DMPMap = new DMPMap({
      type: 'pageShow',
      body: {
        bridgeId: webviewId
      }
    })
    DMPChannelProxyNext.ContainerToService(msg, this.app.appIndex)
  }

  onHide(webviewId: number) {
    DMPLogger.i(Tags.ON_PAGE_HIDE, `webviewId:${webviewId}`)
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