export class DMPIdProvider {
  private static _stackId: number = 1
  private static _webviewId: number = 1

  get stackId(): number {
    return DMPIdProvider._stackId
  }

  static increaseStackId() {
    DMPIdProvider._stackId++
  }

  static generateStackId(): number {
    DMPIdProvider.increaseStackId()

    return DMPIdProvider._stackId
  }

  static get webViewId(): number {
    return DMPIdProvider._webviewId
  }

  static generateWebViewId(): number {
    DMPIdProvider.increaseWebViewId()

    return DMPIdProvider._webviewId
  }

  static increaseWebViewId() {
    DMPIdProvider._webviewId++
  }
}
