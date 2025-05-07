
@Component
export struct Loading {
  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)

  aboutToAppear(): void {


  }

  build() {
    Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
      Canvas(this.context)
        .width('100%')
        .height('100%')
        .onReady(() => {
          const maxWidth = this.context.width;
          const maxHeight = this.context.height;

          // 清空画布
          this.context.clearRect(0, 0, maxWidth, maxHeight);

          // 开始路径
          this.context.beginPath();

          // 圆心坐标和半径
          const centerX = maxWidth / 2; // 圆心X坐标
          const centerY = maxHeight / 2; // 圆心Y坐标
          const radius = Math.min(maxWidth, maxHeight) / 2 - 1 - 5; // 半径-笔宽度一半-小球半径

          // 绘制圆形
          this.context.arc(centerX, centerY, radius, 0, Math.PI * 2);

          // 设置线条样式
          this.context.strokeStyle = '#ffF6F6F8'; // 线颜色
          this.context.lineWidth = 2;
          this.context.lineCap = "round";
          this.context.lineJoin = "round";

          // 描边
          this.context.stroke();

          // 绘制左侧的绿色实心圆
          const smallCircleX = centerX - radius; // 左侧小圆心的X坐标
          const smallCircleY = centerY; // 小圆心Y坐标
          const smallCircleRadius = 5; // 小圆半径

          this.context.beginPath(); // 开始新路径
          this.context.arc(smallCircleX, smallCircleY, smallCircleRadius, 0, Math.PI * 2); // 绘制小圆
          this.context.fillStyle = '#5EA45F'; // 填充颜色为绿色
          this.context.fill(); // 填充小圆

        })
    }
    //单位都用vp
    .width('100%')
    .height('100%')

  }
}
