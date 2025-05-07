import { DMPMap } from '../../Utils/DMPMap';

//JSApp包配置信息
export class DMJSAppBundleConfig {
  public appId: string = '';
  public versionCode: number = 0;
  public versionName: string = '';
  public path: string = '';

  public static fromJson(dictionary: DMPMap | null): DMJSAppBundleConfig | null {
    if (dictionary == null) {
      return null;
    }
    let config = new DMJSAppBundleConfig();
    config.appId = dictionary.get('appId');
    config.versionCode = dictionary.get('versionCode');
    config.versionName = dictionary.get('versionName');
    config.path = dictionary.get('path');
    return config;
  }
}
