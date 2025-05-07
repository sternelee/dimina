import { PhotoView } from '@ohos/photoview';
import { DMPWindowUtil } from '../../Utils/WindowUtils';
import { DMPApp } from '../../DApp/DMPApp';
import { display } from '@kit.ArkUI';
import { DRouter } from '../../Navigator/DRouter';

@Component
export struct DMPPhotoPreview {
  @Prop uri: string
  @Prop param: Map<string, Object>
  @State imageUrls: [string] = this.param?.get('urls') as [string]
  private swipeController = new SwiperController()
  private data: MyDataSource = new MyDataSource([])
  private defaultIndex: number = this.param?.get('index') as number
  private realHeight = 0

  static ROUTE_NAME = 'onetravel://dimina/photopreview'

  aboutToAppear(): void {
    let dataList = new Array<PhotoView.Model>()
    this.imageUrls.forEach((imageUrl) => {
      if (imageUrl) {
        const data: PhotoView.Model = new PhotoView.Model();
        data.setImageURI(imageUrl)
          .setScale(1, false)
          .setImageFit(ImageFit.Contain)
          .setZoomable(false)
          .setMaximumScale(1.5)
          .setMinimumScale(0.8)
        dataList.push(data)
      }
    })
    this.data = new MyDataSource(dataList)
    const screentHeight = display.getDefaultDisplaySync().height
    const vpHidth = px2vp(screentHeight)
    this.realHeight = vpHidth - 55 - px2vp(DMPWindowUtil.getTopSafeArea(DMPApp.getWindowStage()))
  }

  @Builder
  build() {
    NavDestination() {
      Column() {
        Column() {
          Blank()
            .height(px2vp(DMPWindowUtil.getTopSafeArea(DMPApp.getWindowStage())))
          Stack() {
            Text('图片预览')
              .height('100%')
              .width('100%')
              .fontSize(18)
              .fontColor('#000000')
              .fontWeight('500')
              .textAlign(TextAlign.Center)
            Image($r('app.media.ic_dmp_back_black'))
              .width(55)
              .height('100%')
              .padding(15)
              .align(Alignment.Start)
              .onClick((event?: ClickEvent) => {

                DRouter.getInstance().pop();
              })
          }
          .width('100%')
          .height('55')
          .alignContent(Alignment.Start)
        }.width('100%')
        .backgroundColor('#ffffff')

        Swiper(this.swipeController) {
          LazyForEach(this.data, (item: PhotoView.Model) => {
            PhotoView({ model: item })
          })
        }
        .index(this.defaultIndex)
        .cachedCount(2)
        .loop(true)
        .width('100%')
        .height(this.realHeight)
        .padding({
          bottom: 30,
        })
      }
    }.hideTitleBar(true)

  }
}

class MyDataSource implements IDataSource {
  private list: PhotoView.Model[] = []
  private listener?: DataChangeListener

  constructor(list: PhotoView.Model[]) {
    this.list = list
  }

  totalCount(): number {
    return this.list.length
  }

  getData(index: number): PhotoView.Model {
    return this.list[index]
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    this.listener = listener
  }

  unregisterDataChangeListener() {
  }
}