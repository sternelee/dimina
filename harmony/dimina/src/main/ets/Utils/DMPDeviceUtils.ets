import { DMPMap } from './DMPMap';
import { display, window } from '@kit.ArkUI';


export class DMPDeviceUtil {
  static safeAreaAndDisplayWHCache: DMPMap | undefined

  // 同步方法，此方法依赖 prepareSafeAreaAndDisplayWH 提前调用
  static getSafeAreaAndDisplayWHSync(): DMPMap {
    return DMPDeviceUtil.safeAreaAndDisplayWHCache!
  }

  static async prepareSafeAreaAndDisplayWH(context: Context): Promise<DMPMap> {
    if (!DMPDeviceUtil.safeAreaAndDisplayWHCache) {
      let result = new DMPMap()

      result.set('safeArea', await DMPDeviceUtil.getSafeArea(context))
      result.setAll(await DMPDeviceUtil.getDisplayWH(context))

      DMPDeviceUtil.safeAreaAndDisplayWHCache = result

      return DMPDeviceUtil.safeAreaAndDisplayWHCache
    } else {
      return DMPDeviceUtil.safeAreaAndDisplayWHCache
    }
  }

  static async getDisplayWH(context: Context): Promise<DMPMap> {
    let result = new DMPMap()

    let windowClass: window.Window | undefined = undefined;

    windowClass = await window.getLastWindow(context)

    // 获取状态栏高度
    let statusArea = windowClass!.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
    const statusBarHeight = statusArea.topRect.height;

    // 获取导航栏高度
    let navigationArea = windowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
    const navigationHeight = navigationArea.bottomRect.height;

    const displayInfo: display.Display = display.getDefaultDisplaySync()
    const displayWidth = displayInfo.width
    const displayHeight = displayInfo.height
    const density = displayInfo.densityDPI
    const densityPixels = displayInfo.densityPixels
    const scaledDensity = displayInfo.scaledDensity

    result.set('screenWidth', Math.round(px2vp(displayWidth)));
    result.set('screenHeight', Math.round(px2vp(displayHeight)));
    result.set('windowWidth', Math.round(px2vp(displayWidth)));
    result.set('windowHeight', Math.round(px2vp(displayHeight) - px2vp(statusBarHeight)-px2vp(navigationHeight)));
    result.set('statusBarHeight', Math.round(px2vp(statusBarHeight)));
    result.set('navigationHeight', Math.round(px2vp(navigationHeight)));
    result.set('pixelRatio', densityPixels);

    return result
  }


  static async getSafeArea(context: Context): Promise<DMPMap> {

    let windowClass: window.Window | undefined = undefined;
    windowClass = await window.getLastWindow(context)

    // 获取状态栏高度
    let statusArea = windowClass!.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
    const statusBarHeight = statusArea.topRect.height;

    const displayInfo: display.Display = display.getDefaultDisplaySync()
    const displayWidth = displayInfo.width
    const displayHeight = displayInfo.height


    const right = Math.ceil(px2vp(displayWidth));
    const bottom = Math.ceil(px2vp(displayHeight));
    const left = 0;
    const top = Math.ceil(px2vp(statusBarHeight));
    const width = Math.ceil(px2vp(displayWidth));
    const height = Math.ceil(px2vp(displayHeight) - top);

    let result = new DMPMap({
      'right': right,
      'bottom': bottom,
      'left': left,
      'top': top,
      'width': width,
      'height': height
    })

    return result;
  }
}