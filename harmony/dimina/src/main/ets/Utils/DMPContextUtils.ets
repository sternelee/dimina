import { isMainThread } from '../Bridges/DMPTSUtil';
import { bundleManager, common } from "@kit.AbilityKit";

export class DMPContextUtils {
  private static context: common.UIAbilityContext;

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

  //宿主模式
  private static _isDebugMode: boolean | null = null;

  public static get isDebugMode(): boolean {
    if (DMPContextUtils._isDebugMode == null) {
      const bundleFlags = bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION;
      const bundleInfo = bundleManager.getBundleInfoForSelfSync(bundleFlags);
      DMPContextUtils._isDebugMode = bundleInfo.appInfo.debug
    }
    return DMPContextUtils._isDebugMode
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

