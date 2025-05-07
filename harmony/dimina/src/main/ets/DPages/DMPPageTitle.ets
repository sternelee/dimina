import { DMPApp } from '../DApp/DMPApp'
import { DMPPageStyle } from './DMPPageStyle'
import { DMPWindowUtil } from '../Utils/WindowUtils'
import { DMPPageRecord } from '../Navigator/DMPPageRecord'
import { DMPAppManager } from '../DApp/DMPAppManager'

@Component
export struct DMPPageTitle {
  @Prop
  pageRecord: DMPPageRecord
  @Prop
  appIndex: number
  @Prop
  webViewId: number

  aboutToAppear(): void {

  }

  build() {
    Column() {
      Blank()
        .height(px2vp(DMPWindowUtil.getTopSafeArea(DMPApp.getWindowStage())))
      Stack() {
        Text(this.getPageStyle(this.pageRecord)?.getTitleString() ?? '')
          .height('100%')
          .width('100%')
          .fontSize(18)
          .fontColor(this.getPageStyle(this.pageRecord)?.getTitleTextColor() ?? '#000000')
          .fontWeight('500')
          .textAlign(TextAlign.Center)

        Image($r('app.media.ic_dmp_back_black'))
          .width(55)
          .height('100%')
          .padding(15)
          .align(Alignment.Start)
          .onClick((event?: ClickEvent) => {
            const embedController = DMPAppManager.sharedInstance().getApp(this.appIndex)?.getWebController(this.webViewId)?.subController
            if (embedController?.accessBackward()) {
              embedController.backward()
            } else  {
              DMPAppManager.sharedInstance().getApp(this.appIndex)?.navigatorManager.getCurNavigator()?.pop()
            }
          })
      }
      .width('100%')
      .height('55')
      .alignContent(Alignment.Start)
    }.width('100%')
    .backgroundColor(this.getPageStyle(this.pageRecord)?.getNavigationBarBackGroundColor() ?? '#ffffff')
  }


  private getPageStyle(_: DMPPageRecord): DMPPageStyle | undefined {
    const pageRecord = DMPAppManager.sharedInstance().getApp(this.appIndex)?.navigatorManager.getPageRecordById(this.webViewId)
    if (pageRecord) {
      return pageRecord.pageStyle
    }
    return undefined;
  }
}