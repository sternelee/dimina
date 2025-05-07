import { Loading } from "./DMPLoading"

@Component
export struct LaunchLoading {
  @State
  rotateAngle: number = 0
  color: string = '#ff00ff'
  text: string = 'W2'
  name: string = "小程序助手官方demo"

  build() {
    Column() {
      Stack() {
        Loading()
          .onAppear(() => {
            this.rotateAngle = 360
          })
          .rotate({ angle: this.rotateAngle })
          .animation({
            duration: 2000,
            curve: Curve.Friction,
            delay: 0,
            iterations: -1, // 设置-1表示动画无限循环
            playMode: PlayMode.Normal,
            expectedFrameRateRange: {
              min: 20,
              max: 120,
              expected: 90,
            }
          })
          .width(90)
          .height(90)
        Text('小')
          .fontColor(Color.White)
          .backgroundColor(this.color)
          .width(50)
          .height(50)
          .borderRadius(60)
          .align(Alignment.Center)
          .textAlign(TextAlign.Center)
        Text(this.name).fontSize(18).fontColor(Color.Black).margin({top:150})
      }.align(Alignment.Center).alignContent(Alignment.Center).flexGrow(1)
    }.width('100%').height('100%').backgroundColor(Color.White)

  }
}