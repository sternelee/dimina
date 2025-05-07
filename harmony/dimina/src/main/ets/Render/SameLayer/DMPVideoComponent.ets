import { DMPAvPlayer } from './DMPAvPlayer'
import webview from '@ohos.web.webview'
import { VideoParams } from './DMPComponetParams'
import { DMPMap } from '../../Utils/DMPMap'


@Builder
export function VideoBuilder(params: DMPMap) {
  VideoComponent({ params: params.toObject<VideoParams>() })
    .backgroundColor(Color.Green)
}

@Component
struct VideoComponent {
  @Prop params: VideoParams
  @State bkColor: Color = Color.Red
  testController: WebviewController = new webview.WebviewController();
  mXComponentController: XComponentController = new XComponentController();
  @State player_changed: boolean = false;
  player?: DMPAvPlayer;

  build() {
    Column() {
      XComponent({ id: 'video_player_id', type: XComponentType.SURFACE, controller: this.mXComponentController })
        .width(280)
        .height(465)
        .border({ width: 1, color: Color.Red })
        .onLoad(() => {
          this.player = new DMPAvPlayer();
          this.player.setSurfaceID(this.mXComponentController.getXComponentSurfaceId());
          this.player_changed = !this.player_changed;
          this.player.avPlayerLive(this.params!.src!)
        })
    }
    .width(this.params!.width)
    .height(this.params!.height)
  }
}
