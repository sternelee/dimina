import { DMPPageStyle } from '../DPages/DMPPageStyle';
import { DMPLogger } from '../EventTrack/DMPLogger';
import { Tags } from '../EventTrack/Tags';
import { DMPMap } from '../Utils/DMPMap';
import { DMPContainerBridgesModule } from './DMPContainerBridgesModule'

import { DMPBridgeCallback } from './DMPTSUtil'

export class DMPContainerBridgesModuleNavigationBar extends DMPContainerBridgesModule {
  getExportMethods(): string[] {
    return ['setNavigationBarTitle', 'setNavigationBarColor', 'setNavigationTitleColor', 'showNavigationBar',
      'hideNavigationBar'];
  }

  setNavigationBarTitle(data: DMPMap, callback: DMPBridgeCallback, webViewId: number) {
    const title: string = data.get('title');
    const navStyle =
      DMPMap.createFromDMPMap(this.app.navigatorManager.getPageRecordById(webViewId)?.pageStyle?.navStyle)
    navStyle.set('navigationBarTitleText', title)
    this.app.navigatorManager.getPageRecordById(webViewId)!.pageStyle =
      new DMPPageStyle(navStyle ?? new DMPMap(), this.app.appIndex)
    this.invokeSuccessCallback(callback, null)
  }

  setNavigationBarColor(data: DMPMap, callback: DMPBridgeCallback, webViewId: number) {
    const backgroundColor: string = data.get('backgroundColor');
    const navStyle =
      DMPMap.createFromDMPMap(this.app.navigatorManager.getPageRecordById(webViewId)!.pageStyle?.navStyle)
    navStyle.set('navigationBarBackgroundColor', backgroundColor)
    this.app.navigatorManager.getPageRecordById(webViewId)!.pageStyle =
      new DMPPageStyle(navStyle ?? new DMPMap(), this.app.appIndex)
    DMPLogger.d(Tags.BRIDGE, 'navStyle=' + navStyle.toStr())
    this.invokeSuccessCallback(callback, null)
  }

  setNavigationTitleColor(data: DMPMap, callback: DMPBridgeCallback, webViewId: number) {
    let titleColor: string = data.get('titleColor');
    const navStyle =
      DMPMap.createFromDMPMap(this.app.navigatorManager.getPageRecordById(webViewId)!.pageStyle?.navStyle)
    navStyle.set('navigationBarTextColor', titleColor)
    this.app.navigatorManager.getPageRecordById(webViewId)!.pageStyle =
      new DMPPageStyle(navStyle ?? new DMPMap(), this.app.appIndex)
    this.invokeSuccessCallback(callback, null)
  }

  showNavigationBar(data: DMPMap, callback: DMPBridgeCallback, webViewId: number) {
    const navStyle =
      DMPMap.createFromDMPMap(this.app.navigatorManager.getPageRecordById(webViewId)!.pageStyle?.navStyle)
    navStyle.set('isHide', false)
    this.app.navigatorManager.getPageRecordById(webViewId)!.pageStyle =
      new DMPPageStyle(navStyle ?? new DMPMap(), this.app.appIndex)
    this.invokeSuccessCallback(callback, null)
  }

  hideNavigationBar(data: DMPMap, callback: DMPBridgeCallback, webViewId: number) {
    const navStyle =
      DMPMap.createFromDMPMap(this.app.navigatorManager.getPageRecordById(webViewId)!.pageStyle?.navStyle)
    navStyle.set('isHide', true)
    this.app.navigatorManager.getPageRecordById(webViewId)!.pageStyle =
      new DMPPageStyle(navStyle ?? new DMPMap(), this.app.appIndex)
    this.invokeSuccessCallback(callback, null)
  }
}



