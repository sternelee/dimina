import { common,bundleManager } from '@kit.AbilityKit';
import { isMainThread } from '../Bridges/DMPTSUtil';

export class DMPContextUtils {
  private static context: common.UIAbilityContext;

  private static _debugMode: boolean | null = null;

  static init(context: common.UIAbilityContext) {
    DMPContextUtils.context = context;
  }

  static getUIAbilityContext(): common.UIAbilityContext {
    if (isMainThread()) {
      return DMPContextUtils.context;
    } else {
      const c = DMPWorkerContext.sharedInstance();
      return c.context!;
    }
  }

  public static get debugMode(): boolean {
    if (DMPContextUtils._debugMode == null) {
      const bundleFlags = bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION;
      const bundleInfo = bundleManager.getBundleInfoForSelfSync(bundleFlags);
      DMPContextUtils._debugMode = bundleInfo.appInfo.debug
    }
    return DMPContextUtils._debugMode
  }
}

// 因为系统限制，这个 Context 只在 worker 线程使用，
// https://developer.huawei.com/consumer/cn/doc/harmonyos-faqs-V5/faqs-ability-30-V5
export class DMPWorkerContext {
  private static instance: DMPWorkerContext
  context?: common.UIAbilityContext;

  static sharedInstance() {
    if (!DMPWorkerContext.instance) {
      DMPWorkerContext.instance = new DMPWorkerContext();
    }
    return DMPWorkerContext.instance;
  }


  private constructor() {

  }
}

