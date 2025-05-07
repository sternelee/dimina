import { DMPLogger } from '../../EventTrack/DMPLogger'
import { MapParams } from './DMPComponetParams'
import { Tags } from '../../EventTrack/Tags'
import { DMPAppManager } from '../../DApp/DMPAppManager'
import { DMPWebViewController } from '../../HybridContainer/DMPWebViewController'
import { DMPMap } from '../../Utils/DMPMap'


@Builder
export function MapBuilder(params: DMPMap) {
  DMPMapComponent({ params: params.toObject<MapParams>() }).backgroundColor(Color.Green)
}

@Component
struct DMPMapComponent {
  @Prop params: MapParams
  private controller: XComponentController = new XComponentController();
  private webViewController?: DMPWebViewController;

  aboutToAppear(): void {
    DMPLogger.d(Tags.MAP, "DDMapComponent aboutToAppear")
    const app = DMPAppManager.sharedInstance().getApp(this.params.appIndex!)
    this.webViewController = app?.getWebController(this.params.parentWebViewId!);
  }

  aboutToDisappear(): void {
    DMPLogger.d(Tags.MAP, "DDMapComponent aboutToDisappear")
    if (this.webViewController) {
      const app = DMPAppManager.sharedInstance().getApp(this.params.appIndex!)
      if (app) {
        app.mapManager.unBind(this.webViewController)
      }
    }
  }

  build() {
   Column(){

   }
  }
}

