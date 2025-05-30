import { BusinessError } from '@ohos.base';
import { DMPApp } from '../DApp/DMPApp';
import { DMPPageRecord as DMPPageRecord } from './DMPPageRecord';
import { DMPLaunchConfig, DMPOpenType } from '../DApp/config/DMPLaunchConfig';
import { DMPLogger } from '../EventTrack/DMPLogger';
import { Tags } from '../EventTrack/Tags';
import { DMPPageStyle } from '../DPages/DMPPageStyle';
import { DMPMap } from '../Utils/DMPMap';
import { DMPPageLifecycle } from '../DPages/DMPPageLifecycle';
import { DMPBridgeCallback, DMPBridgeCallbackType, DMPTSUtil } from '../Bridges/DMPTSUtil';
import { promptAction } from '@kit.ArkUI';
import { DMPStack } from '../Utils/DMPStack';
import { DRouter } from './DRouter';
import { DMPPage } from '../DPages/DMPPage';


export class DMPNavigator {
  private _stacks: DMPStack<DMPPageRecord> = new DMPStack();

  public get stacks(): DMPStack<DMPPageRecord> {
    return this._stacks;
  }

  private app: DMPApp
  private pageLifecycle: DMPPageLifecycle

  constructor(app: DMPApp) {
    this.app = app;
    this.pageLifecycle = new DMPPageLifecycle(app)
  }

  public isContainsWebViewId(webViewId: number): boolean {
    let isContains = false;
    for (let record of this._stacks.data) {
      if (record.webViewId == webViewId) {
        isContains = true;
        break
      }
    }
    return isContains;
  }

  pageCount(): number {
    return this._stacks.size()
  }


  async navigateTo(stackId: number, params: DMPMap) {
    this.app.container.isNavigating = true;
    DMPLogger.d(Tags.NAVIGATOR, 'navigateTo')
    const pagePath: string = params.get('pagePath')

    const callback: DMPBridgeCallback = (_: DMPMap, cbType: DMPBridgeCallbackType) => {
      if (cbType == DMPBridgeCallbackType.Success) {
        this.openPage(stackId, pagePath, params)
      }
      if (cbType == DMPBridgeCallbackType.Fail) {
        promptAction.showToast({ message: '子包加载失败', duration: 1, alignment: Alignment.Center })
      }
      DMPLogger.d(Tags.NAVIGATOR, 'loadSubPackage callback result=' + cbType)
    }
    this.loadSubPackage(pagePath, callback)

  }

  async launch(stackId: number, launchConfig: DMPLaunchConfig) {
    DMPLogger.d(Tags.NAVIGATOR, 'launchPageNext')
    const params = new DMPMap()
    params.set('query', launchConfig?.query ?? new DMPMap())

    const pagePath: string = launchConfig.appEntryPath!
    const callback: DMPBridgeCallback = (_, cbType: DMPBridgeCallbackType) => {
      DMPLogger.d(Tags.LAUNCH, "loadSubPackage end");
      if (cbType == DMPBridgeCallbackType.Success) {
        this.openPage(stackId, pagePath, params, launchConfig.openType, launchConfig?.customLaunchPageCallBack)
      }
      if (cbType == DMPBridgeCallbackType.Fail) {
        promptAction.showToast({ message: '子包加载失败', duration: 1, alignment: Alignment.Center })
      }
      DMPLogger.d(Tags.NAVIGATOR, 'loadSubPackage callback result=' + cbType)
    }
    DMPLogger.d(Tags.LAUNCH, "loadSubPackage start");
    this.loadSubPackage(pagePath, callback)

  }

  async relaunchTo(params: DMPMap) {
    DMPLogger.d(Tags.NAVIGATOR, 'relaunchTo')
    const pagePath: string = params.get('pagePath')

    const callback: DMPBridgeCallback = (_, cbType: DMPBridgeCallbackType) => {
      if (cbType == DMPBridgeCallbackType.Success) {
        this.realReLaunchTo(pagePath, params)
      }
      if (cbType == DMPBridgeCallbackType.Fail) {
        promptAction.showToast({ message: '子包加载失败', duration: 1, alignment: Alignment.Center })
      }
      DMPLogger.d(Tags.NAVIGATOR, 'loadSubPackage callback result=' + cbType)
    }
    this.loadSubPackage(pagePath, callback)

  }


  private realReLaunchTo(pagePath: string, params: DMPMap) {
    const launchConfig = this.app.getLaunchConfig();
    if (launchConfig) {
      if (pagePath.startsWith('/') && pagePath.length > 1) {
        const realPagePath = pagePath.substring(1)
        launchConfig.appEntryPath = realPagePath
      } else {
        launchConfig.appEntryPath = pagePath
      }

      launchConfig.query = params.get('query')
    }
    this.app.reLaunch()

  }

  async redirectTo(stackId: number, params: DMPMap) {
    DMPLogger.d(Tags.NAVIGATOR, 'redirectTo')
    const pagePath: string = params.get('pagePath')

    const callback: DMPBridgeCallback = (_, cbType: DMPBridgeCallbackType) => {
      if (cbType == DMPBridgeCallbackType.Success) {
        this.realRedirectTo(stackId, pagePath, params)
      }
      if (cbType == DMPBridgeCallbackType.Fail) {
        promptAction.showToast({ message: '子包加载失败', duration: 1, alignment: Alignment.Center })
      }
      DMPLogger.d(Tags.NAVIGATOR, 'loadSubPackage callback result=' + cbType)
    }
    this.loadSubPackage(pagePath, callback)
  }


  private realRedirectTo(stackId: number, pagePath: string, params: DMPMap) {
    DMPLogger.i(Tags.REDIRECT, params.toStr())
    this.pageLifecycle.onUnload(this.app.currentWebViewId)
    this.popPageRecord()

    const navStyle = this.app.bundleManager.getJsAppModuleConfig()!.getPageConfigNext(pagePath)
    const webViewNodeController = this.app.webViewCachePool.getWebViewNodeController(pagePath, params)
    const newWebViewId = webViewNodeController.webViewId
    let currentPageRecord = this.app.navigatorManager.getTopPageRecord();
    let pageRecord =
      new DMPPageRecord(newWebViewId, currentPageRecord?.webViewId ?? -1, pagePath, this.app.appIndex,
        webViewNodeController)
    pageRecord.params = params
    pageRecord.pageStyle = new DMPPageStyle(navStyle ?? new DMPMap(), this.app.appIndex)
    this.pushPageRecordStack(pageRecord)
    //加载资源,必须要在pageRecord 之后
    webViewNodeController.loadResource(pagePath)
    try {
      DRouter.getInstance()
        .build('onetravel://dimina/page')
        .putExtra("appIndex", this.app.appIndex)
        .putExtra("webViewId", pageRecord.webViewId)
        .putExtra("stackId", stackId)
        .setNavMode(DMPOpenType.Insert)
        .start()
    } catch (err) {
      DMPLogger.e(Tags.NAVIGATOR, `msg: ${(err as BusinessError).message}`)
    }

    this.pageLifecycle.onShow(newWebViewId)
  }

  async pop(delta: number = 1, animated: boolean = true, canDestroy = true, isReLaunch = false) {
    DMPLogger.i(Tags.NAVIGATOR, 'pop')
    try {
      if (this.app.container.isNavigating) {
        return
      }
      //处理多栈
      if (delta > this._stacks.size()) {
        delta = this._stacks.size();
      }
      for (let i = 0; i < delta; i++) {
        this.pageLifecycle.onUnload(this.app.currentWebViewId)
        DRouter.getInstance().pop(animated)
        // DNavigation.pop()
        this.popPageRecord()
      }
      //ReLaunch 模式下，如自定义页面或启动模式是Insert情况，会导致页面少回退一个，但是小程序页面必须要解绑
      if (isReLaunch && this._stacks.size() > 0) {
        this.pageLifecycle.onUnload(this.app.currentWebViewId)
        this.popPageRecord()
      }
      //销毁这个navigator
      if (this._stacks.size() < 1) {
        this.app.navigatorManager.popNavigator()
      }
      this.app.navigatorManager.notifyPopListener()
      if (canDestroy && !this.app.appConfig.isKeepAlive) {
        //销毁app
        if (this.app.navigatorManager.isEmpty()) {
          this.app.navigatorManager.clear()
          this.app.destroyEngine()
          this.app.destroyApp()
          return
        }
      }
      let currentPageRecord = this.app.navigatorManager.getTopPageRecord();
      this.pageLifecycle.onShow(currentPageRecord?.webViewId ?? -1)

    } catch (err) {
      DMPLogger.e(Tags.BRIDGE, `msg: ${(err as BusinessError).message}`)
    }
  }

  async navigateBack(delta: number, animated: boolean = true, canDestroy = true, isReLaunch = false) {
    DMPLogger.d(Tags.NAVIGATOR, 'navigateBack')
    this.pop(delta, animated, canDestroy, isReLaunch)
  }

  //打开页面
  private openPage(stackId: number, pagePath: string, params: DMPMap,
    openType: DMPOpenType = DMPOpenType.NavigateTo,
    customLaunchPageCallBack?: (record: DMPPageRecord, path: String, stackId: number, isRelaunch?: boolean) => void) {
    DMPLogger.i(Tags.LAUNCH, "openPage");
    DMPLogger.d(Tags.LAUNCH, "notify page.onHide start");
    this.pageLifecycle.onHide(this.app.currentWebViewId)
    DMPLogger.d(Tags.LAUNCH, "notify page.onHide end");
    const pageRecord = this.preLoadPage(pagePath, params)

    try {
      if (customLaunchPageCallBack) {
        customLaunchPageCallBack(pageRecord, pagePath, stackId, this.app.getLaunchConfig()?.isRelaunch)
      } else {
        DRouter.getInstance()
          .build(DMPPage.ROUTE_NAME)
          .putExtra("appIndex", this.app.appIndex)
          .putExtra("webViewId", pageRecord.webViewId)
          .putExtra("stackId", stackId)
          .setNavMode(openType)
          .start()
      }
    } catch (err) {
      DMPLogger.e(Tags.NAVIGATOR, `msg: ${(err as BusinessError).message}`)
    }

    this.pageLifecycle.onShow(pageRecord.webViewId)

  }

  private popPageRecord() {
    this._stacks.pop()
    this.app.navigatorManager.popGlobalPageRecord()
  }

  private pushPageRecordStack(pageRecord: DMPPageRecord) {
    this._stacks.push(pageRecord)
    this.app.navigatorManager.pushGlobalPageRecord(pageRecord)
  }

  private loadSubPackage(pagePath: string, callback: DMPBridgeCallback) {
    const loadSubPackageOwner = this.app.appModuleManager.getModuleObjectByMethodName('loadSubPackage')
    const invokeParams = new DMPMap()
    const packageName: string = this.app?.bundleManager?.getJsAppModuleConfig()?.getRootPackage(pagePath)
    invokeParams.set('package', packageName)
    DMPTSUtil.invokeNativeMethod(loadSubPackageOwner, 'loadSubPackage', invokeParams, this.app.currentWebViewId,
      callback)
  }

  private preLoadPage(pagePath: string, params: DMPMap): DMPPageRecord {
    DMPLogger.i(Tags.LAUNCH, "preLoadPage start")
    //获取预加载webview记录
    const webViewNodeController = this.app.webViewCachePool.getWebViewNodeController(pagePath, params)
    const newWebViewId = webViewNodeController.webViewId

    //创建页面记录
    const currentPageRecord = this.app.navigatorManager.getTopPageRecord();
    const pageRecord =
      new DMPPageRecord(newWebViewId, currentPageRecord?.webViewId ?? -1, pagePath, this.app.appIndex,
        webViewNodeController)
    pageRecord.params = params
    const navStyle = this.app.bundleManager.getJsAppModuleConfig()!.getPageConfigNext(pagePath)
    pageRecord.pageStyle = new DMPPageStyle(navStyle ?? new DMPMap(), this.app.appIndex)
    this.pushPageRecordStack(pageRecord)
    webViewNodeController.loadResource(pagePath)
    DMPLogger.i(Tags.LAUNCH, "preLoadPage end")
    return pageRecord;
  }
}
