import { DMPMap } from '../../Utils/DMPMap';


export class DMPJSSdkBundleConfig {
  public versionCode: number = 0;
  public versionName: string = '';

  public static fromJson(dictionary: DMPMap | null): DMPJSSdkBundleConfig | null {
    if (dictionary == null) {
      return null;
    }
    let config = new DMPJSSdkBundleConfig();
    config.versionCode = dictionary.get('versionCode');
    config.versionName = dictionary.get('versionName');
    return config;
  }
}