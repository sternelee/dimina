import { DMPAppManager } from '../../DApp/DMPAppManager';
import { DMPLogger } from '../../EventTrack/DMPLogger';
import { Tags } from '../../EventTrack/Tags';
import { EmbedWebView } from './EmbedWebView';
import { DMPIdProvider } from '../../Navigator/DMPIdProvider';
import { DMPMap } from '../../Utils/DMPMap';
import { WebViewParams } from './DMPComponetParams';

@Builder
export function WebViewBuilder(params: DMPMap) {
  DMPEmbedWebViewComponent({ params: params.toObject<WebViewParams>() }).backgroundColor(Color.Green)
}

@Component
struct DMPEmbedWebViewComponent {
  @Prop params: WebViewParams
  private controller: XComponentController = new XComponentController();

  aboutToAppear(): void {
    DMPLogger.d(Tags.EMBED_WEB_VIEW, "DMPEmbedWebViewComponent aboutToAppear")
    const app = DMPAppManager.sharedInstance().getApp(this.params.appIndex!)!
  }

  aboutToDisappear(): void {
    DMPLogger.d(Tags.MAP, "DMPEmbedWebViewComponent aboutToDisappear")

  }

  build() {
    XComponent({ id: 'web-container', type: 'component', controller: this.controller }) {
      EmbedWebView({
        data: this.params,
        webViewId: DMPIdProvider.generateWebViewId(),
        appIndex: this.params.appIndex,
        parentWebViewId: this.params.parentWebViewId
      })
    }.width(this.params.width)
    .height(this.params.height).onDestroy(() => {
      DMPLogger.d(Tags.MAP, "DMPEmbedWebViewComponent onDestroy")
    })
  }
}

