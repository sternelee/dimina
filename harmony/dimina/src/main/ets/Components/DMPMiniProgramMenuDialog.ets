@CustomDialog
export struct DMPMiniProgramMenuDialog {
  controller: CustomDialogController
  private canvasSettings: RenderingContextSettings = new RenderingContextSettings(true)
  private reenterIconContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.canvasSettings)
  private closeIconContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.canvasSettings)
  private appName: string = ''
  private buildController?: () => CustomDialogController
  private onReenter?: () => void
  private onClose?: () => void

  build() {
    Column() {
      Row() {
        Stack() {
          Text(this.getAppInitial())
            .fontSize(18)
            .fontColor('#8a8a8a')
            .fontWeight(FontWeight.Medium)
        }
        .width(44)
        .height(44)
        .borderRadius(22)
        .backgroundColor('#f4f4f4')
        .alignContent(Alignment.Center)

        Column() {
          Text(this.appName || '小程序')
            .fontSize(18)
            .fontColor('#202020')
            .fontWeight(FontWeight.Bold)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text('小程序')
            .fontSize(14)
            .fontColor('#9a9a9a')
            .margin({ top: 3 })
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 14 })
      }
      .width('100%')
      .height(84)
      .padding({ left: 24, right: 24 })
      .alignItems(VerticalAlign.Center)

      Divider()
        .height(1)
        .backgroundColor('#f2f2f2')

      Row({ space: 16 }) {
        this.MenuItem(true, '重新进入\n小程序', () => {
          this.closeDialog()
          this.onReenter?.()
        })
        this.MenuItem(false, '关闭小程序', () => {
          this.closeDialog()
          this.onClose?.()
        })
      }
      .width('100%')
      .height(134)
      .padding({ left: 24, right: 24, top: 20, bottom: 20 })
      .alignItems(VerticalAlign.Top)
      .justifyContent(FlexAlign.Start)

      Divider()
        .height(1)
        .backgroundColor('#ededed')

      Text('取消')
        .width('100%')
        .height(58)
        .fontSize(18)
        .fontColor('#576b95')
        .textAlign(TextAlign.Center)
        .onClick(() => {
          this.closeDialog()
        })
    }
    .width('100%')
    .backgroundColor(Color.White)
    .borderRadius(18)
  }

  @Builder
  private MenuItem(isReenter: boolean, title: string, onClick: () => void) {
    Column() {
      Stack() {
        if (isReenter) {
          Canvas(this.reenterIconContext)
            .width(24)
            .height(24)
            .onReady(() => {
              this.drawReenterIcon(this.reenterIconContext)
            })
        } else {
          Canvas(this.closeIconContext)
            .width(24)
            .height(24)
            .onReady(() => {
              this.drawCloseIcon(this.closeIconContext)
            })
        }
      }
      .width(52)
      .height(52)
      .borderRadius(10)
      .backgroundColor('#f8f8f8')
      .alignContent(Alignment.Center)

      Text(title)
        .width(78)
        .height(34)
        .fontSize(13)
        .fontColor('#686868')
        .textAlign(TextAlign.Center)
        .lineHeight(17)
        .maxLines(2)
        .margin({ top: 8 })
    }
    .width(78)
    .height(94)
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Start)
    .onClick(() => {
      onClick()
    })
  }

  private prepareIconContext(context: CanvasRenderingContext2D): void {
    context.clearRect(0, 0, 24, 24)
    context.strokeStyle = '#333333'
    context.lineWidth = 2
    context.lineCap = 'round'
    context.lineJoin = 'round'
  }

  private drawReenterIcon(context: CanvasRenderingContext2D): void {
    this.prepareIconContext(context)
    context.beginPath()
    context.arc(12, 12, 7.25, 45 * Math.PI / 180, 315 * Math.PI / 180)
    context.stroke()

    context.beginPath()
    context.moveTo(19.68, 9.42)
    context.lineTo(15.29, 8.71)
    context.lineTo(18.97, 5.03)
    context.closePath()
    context.fillStyle = '#333333'
    context.fill()
  }

  private drawCloseIcon(context: CanvasRenderingContext2D): void {
    this.prepareIconContext(context)
    context.beginPath()
    context.moveTo(6.75, 6.75)
    context.lineTo(17.25, 17.25)
    context.moveTo(17.25, 6.75)
    context.lineTo(6.75, 17.25)
    context.stroke()
  }

  private getAppInitial(): string {
    return this.appName.length > 0 ? this.appName.substring(0, 1) : '小'
  }

  private closeDialog() {
    if (this.buildController) {
      this.buildController().close()
    }
  }
}
