//包安装配置
import { DMPLaunchType } from '../../DAppManager/DMPAppConfig';
import { DMPMap } from '../../Utils/DMPMap';

//包管理安装配置信息
export class DMPBundleInstallConfig {
  context: Context;
  launchAppType: DMPLaunchType = DMPLaunchType.OnLine;
  appId: string;
  appIndex: number;
  public appVersion: string = '';
  public appLocalFilePath: string = '';
  public sdkId: string = '';
  public sdkVersion: string = '';
  public sdkLocalFilePath: string = '';
  public bundleVersion: string = '';

  // 外部传入
  public addtionParams?: DMPMap;


  constructor(context: Context, appId: string, appIndex: number) {
    this.context = context;
    this.appId = appId;
    this.appIndex = appIndex;
  }
}