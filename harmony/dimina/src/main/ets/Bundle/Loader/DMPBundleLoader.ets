import { DMPBundleInstallConfig } from '../Model/DMPBundleInstallConfig';
import { DMPBundleLoadInfo } from '../Model/DMPBundleLoadInfo';

export interface DMPBundleLoader {


  //包准备好，允许启动回调
  _launchBundleReady: ((config: DMPBundleLoadInfo) => void) | null;

  //加载错误
  _loadError: ((code: number, errMsg: string) => void) | null;

  //安装配置
  installConfig: DMPBundleInstallConfig | null;

  //安装包信息
  installBundleInfo: DMPBundleLoadInfo | null;

  install(installConfig: DMPBundleInstallConfig, launchBundleReady: ((config: DMPBundleLoadInfo) => void) | null,
    loadComplete?: ((config: DMPBundleLoadInfo) => void) | null,
    loadError?: ((code: number, errMsg: string) => void) | null): Promise<DMPBundleLoadInfo>

  requestServiceJsUri(): Promise<string>
  requestLogicJsUri(): Promise<string>

  //加载配置文件
  requestConfigFile(): Promise<string>

  //当前jsApp目录
  getJsAppDir(): string

  //当前jsApp version
  getJsAppVersion(): string

  //当前jsSdk目录
  getJSSdkDir(): string

  //获取小程序根目录
  getAppRootDir(): string

  //加载分包的 app-service.js
  requestModuleService(module: string): Promise<string>


}