//包配置
import { DMJSAppBundleConfig } from './DMJSAppBundleConfig';
import { DMPJSSdkBundleConfig } from './DMPJSSdkBundleConfig';

//包管理加载信息
export class DMPBundleLoadInfo {
  //小程序id
  appId: string = '';
  appIndex: number = 0;
  //客户端版本信息
  appVersionName: string | null = null;
  appVersionCode: number | null = null;
  cacheVersionName: string | null = null;
  cacheVersionCode: number | null = null;
  //JSApp信息
  localJSAppBundleConfig: DMJSAppBundleConfig | null = null;
  cacheJSAppBundleConfig: DMJSAppBundleConfig | null = null;
  remoteJSAppBundleConfig: DMJSAppBundleConfig | null = null;
  //JSSdk信息
  localJSSdkBundleConfig: DMPJSSdkBundleConfig | null = null;
  cacheJSSdkBundleConfig: DMPJSSdkBundleConfig | null = null;
  remoteJSSdkBundleConfig: DMPJSSdkBundleConfig | null = null;
  //当前正在使用的
  currentJsAppBundleConfig: DMJSAppBundleConfig | null = null;
  currentJsSdkBundleConfig: DMPJSSdkBundleConfig | null = null;
  // 状态值
  updateStrategy: number = 0;

  //应用升级
  isAppUpdate(): Boolean {
    if (this.cacheVersionCode == null || this.cacheVersionCode == 0) {
      return true;
    }
    return this.appVersionCode! > this.cacheVersionCode;
  }


}