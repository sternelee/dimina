import { ActionSheetController } from '../Bridges/Widget/DMPActionSheetController'
import { DMPPageStyle } from '../DPages/DMPPageStyle'
import { DMPWebViewNodeController } from '../DPages/DMPWebViewNodeController'
import { DMPMap } from '../Utils/DMPMap'
import { DomReadyListener } from './DMPNavigatorManager'


@Observed
export class DMPPageRecord {
  webViewId: number
  fromWebViewId: number
  pagePath: string
  params: DMPMap | undefined
  navStyle: DMPMap | undefined
  pageStyle: DMPPageStyle | undefined
  componentParams: Map<string, DMPMap> = new Map()
  isShowLoading: boolean = false;
  showLoadingTitle: string = '';
  showLoadingMask: boolean = false
  appIndex: number
  webViewNodeController: DMPWebViewNodeController
  adjustPosition: number = 0
  actionSheetController?: ActionSheetController;
  domReadyListeners: DomReadyListener[] = [];

  constructor(webViewId: number, fromWebViewId: number, pagePath: string, appIndex: number,
    webViewNodeController: DMPWebViewNodeController) {
    this.pagePath = pagePath;
    this.webViewId = webViewId;
    this.fromWebViewId = fromWebViewId;
    this.appIndex = appIndex;
    this.webViewNodeController = webViewNodeController;
  }
}
