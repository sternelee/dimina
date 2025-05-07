@CustomDialog
export struct BottomSheetDialog {
  @Prop title: string = '';
  @State menuArray: ListMenu[] = [];
  controller: CustomDialogController;
  buildController?: () => CustomDialogController;
  onItemClick?: (index: number) => void;

  build() {
    Column() {
      Text(this.title)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 15, bottom: 15 });
      Divider()
        .height(1)
        .backgroundColor('#F8F8F8')
      ForEach(this.menuArray, (item: ListMenu, index: number) => {
        this.MenuItem(item, index);
        Divider()
          .height(1)
          .backgroundColor('#F8F8F8')
      }, (index: number) => index.toString());
      Text("取消")
        .fontSize(16).padding({ top: 15, bottom: 15 }).width('100%').textAlign(TextAlign.Center).onClick(() => {
        if (this.buildController) {
          this.buildController().close();
        }
      })
    }
    .width('100%')
    .backgroundColor(Color.White)
    .alignItems(HorizontalAlign.Center);
  }

  @Builder
  MenuItem(item: ListMenu, index: number) {
    Row() {
      Text(item.text)
        .fontSize(16)
        .margin({ left: 10 });
    }.justifyContent(FlexAlign.Center)
    .width('100%')
    .height(50)
    .onClick(() => {
      if (this.buildController) {
        this.buildController().close();
      }
      if (this.onItemClick) {
        this.onItemClick(item.index)
      }

    });
  }
}

export class ListMenu {
  index: number
  text: string
  color: string

  constructor(index: number, text: string, color: string = "#333333") {
    this.index = index;
    this.text = text;
    this.color = color;
  }
}