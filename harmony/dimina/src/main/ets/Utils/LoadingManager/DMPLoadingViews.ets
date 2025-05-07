import { DMPLoadingSettings, loadingDialogGlobalSettings } from './DMPLoadingSettings'
import { PromptActionBean } from './DMPPromptActionUtils'

export enum DMPLoadingState {
  LOADING = 'loading',
  SUCCESS = 'success',
  ERROR = 'error',
  INFO = 'info',
  WARN = 'warn',
  TOAST = 'toast',
  PROGRESS = 'progress',
  ICONPROGRESS = 'iconProgress'
}

export class DMPLoadingActionOptions extends PromptActionBean {
  value: string | DMPLoadingSettings = ''
  progress: number = 0

  constructor(state: DMPLoadingState, value: string | DMPLoadingSettings = '', progress: number = 0) {
    super(state)
    this.value = value
    this.progress = progress
  }
}

@Builder
export function DMPLoadingDialogBuilder(options: DMPLoadingActionOptions) {
  DMPLoadingDialogView({
    value: options.value,
    state: options.dialogId as DMPLoadingState,
    progress: options.progress
  })
}

@Component
struct DMPLoadingDialogView {
  @Prop value: string | DMPLoadingSettings = ''
  @Prop state: DMPLoadingState = DMPLoadingState.LOADING
  @Prop progress: number = 0
  private msg: string = ''
  private settings?: DMPLoadingSettings

  aboutToAppear(): void {
    if (typeof this.value == 'string') {
      this.msg = this.value
    } else {
      this.msg = this.value.msg ?? loadingDialogGlobalSettings.msg
      this.settings = this.value
    }
  }

  build() {
    Column({ space: 10 }) {
      if (this.state == DMPLoadingState.LOADING) {
        LoadingProgress()
          .color(this.settings?.tintColor ?? loadingDialogGlobalSettings.tintColor)
          .width('54vp')
          .height('54vp')
      } else if (this.state == DMPLoadingState.SUCCESS) {
        Image(this.settings?.successSrc ?? loadingDialogGlobalSettings.successSrc)
          .fillColor(this.settings?.tintColor ?? loadingDialogGlobalSettings.tintColor)
          .width('44vp')
          .height('44vp')
      } else if (this.state == DMPLoadingState.ERROR) {
        Image(this.settings?.failureSrc ?? loadingDialogGlobalSettings.failureSrc)
          .fillColor(this.settings?.tintColor ?? loadingDialogGlobalSettings.tintColor)
          .width('44vp')
          .height('44vp')
      } else if (this.state == DMPLoadingState.INFO) {
        Image(this.settings?.infoSrc ?? loadingDialogGlobalSettings.infoSrc)
          .fillColor(this.settings?.tintColor ?? loadingDialogGlobalSettings.tintColor)
          .width('44vp')
          .height('44vp')
      } else if (this.state == DMPLoadingState.WARN) {
        Image(this.settings?.warnSrc ?? loadingDialogGlobalSettings.warnSrc)
          .fillColor(this.settings?.tintColor ?? loadingDialogGlobalSettings.tintColor)
          .width('44vp')
          .height('44vp')
      } else if (this.state == DMPLoadingState.ICONPROGRESS) {
        Image(this.settings?.iconProgress ?? loadingDialogGlobalSettings.iconProgress)
          .fillColor(this.settings?.tintColor ?? loadingDialogGlobalSettings.tintColor)
          .width('88vp')
          .height('88vp')
      } else if (this.state == DMPLoadingState.PROGRESS) {
        Stack() {
          Progress({ value: this.progress, total: 100, type: ProgressType.Ring })
            .width('100%')
            .height('100%')
            .color(this.settings?.tintColor ?? loadingDialogGlobalSettings.tintColor)
            .backgroundColor("#4dffffff")
            .style({
              strokeWidth: 5,
              enableSmoothEffect: false,
            })

          Text(`${this.progress}%`)
            .width('100%')
            .height('100%')
            .fontSize('14fp')
            .fontColor(this.settings?.tintColor ?? loadingDialogGlobalSettings.tintColor)
            .textAlign(TextAlign.Center)
        }
        .width('54vp')
        .height('54vp')
      }

      if (this.msg != '') {
        Text(this.msg)
          .fontColor(this.settings?.textColor ?? loadingDialogGlobalSettings.textColor)
          .textAlign(TextAlign.Center)
          .fontSize(this.settings?.fontSize ?? loadingDialogGlobalSettings.fontSize)
      }
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .constraintSize({
      minWidth: '80vp'
    })
    .padding(12)
    .margin(30)
    .backgroundColor(this.state == DMPLoadingState.ICONPROGRESS ? '#FFFFFF' : (this.settings?.backgroundColor ?? loadingDialogGlobalSettings.backgroundColor))
    .borderRadius(this.settings?.borderRadius ?? loadingDialogGlobalSettings.borderRadius)
  }
}
