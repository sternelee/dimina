import { DMPMap } from '../../Utils/DMPMap';

//app-config.json
export class DMPBundleAppConfigNext {
  data: object;
  app: object;
  modules: object;
  pages: string[] | null;
  style: string;
  sitemapLocation: string;
  subPackages: SubPackageConfig[];
  _entryPagePath: string;
  moduleMaps: Map<string, ModuleConfig>

  constructor(data: object) {
    this.data = data
    this.app = data['app']
    this.modules = data['modules']
    this.moduleMaps = DMPMap.toMap<string, ModuleConfig>(this.modules)

    this.pages = this.app['pages'];
    this.style = this.app['style'];
    this.sitemapLocation = this.app['sitemapLocation'];
    this.subPackages = this.app['subPackages'];
    this._entryPagePath = this.app['entryPagePath'];
  }

  public getRootPackage(pagePath: string): string {
    return this.moduleMaps.get(pagePath)?.root ?? "main";
  }

  public isContainsPage(pagePath: string): boolean {
    if (this.moduleMaps.get(pagePath)) {
      return true;
    }
    return false;
  }

  public getModuleConfig(pagePath: string): ModuleConfig | undefined | null {
    return this.moduleMaps.get(pagePath);
  }

  public static fromJsonString(json: string): DMPBundleAppConfigNext | null {
    const dictionary: object = JSON.parse(json);
    let config = new DMPBundleAppConfigNext(dictionary);
    return config;
  }

  get entryPagePath(): string {
    if (!this._entryPagePath || !this._entryPagePath.length) {
      this._entryPagePath = this.pages![0]
    }
    return this._entryPagePath
  }

  set entryPagePath(path: string) {
    this._entryPagePath = path
  }

  getPageConfigNext(pagePath: string): DMPMap {
    const pagePrivateConfig: object = this.modules[pagePath] ?? new Object();
    const appWindowConfig: object = this.app['window'] ?? new Object();

    const mergedConfig = new DMPMap();
    mergedConfig.set('navigationBarTitleText',
      pagePrivateConfig['navigationBarTitleText'] || appWindowConfig['navigationBarTitleText'] || '');
    mergedConfig.set('navigationBarBackgroundColor',
      pagePrivateConfig['navigationBarBackgroundColor'] || appWindowConfig['navigationBarBackgroundColor'] || '#FFFFFF');
    mergedConfig.set('navigationBarTextStyle',
      pagePrivateConfig['navigationBarTextStyle'] || appWindowConfig['navigationBarTextStyle']|| 'black');
    mergedConfig.set('backgroundColor',
      pagePrivateConfig['backgroundColor'] || appWindowConfig['backgroundColor'] || '#fff');
    mergedConfig.set('navigationStyle',
      pagePrivateConfig['navigationStyle'] || appWindowConfig['navigationStyle'] || 'default');
    mergedConfig.set('usingComponents', pagePrivateConfig['usingComponents'] || {});

    return mergedConfig;
  }
}


interface SubPackageConfig {
  root: string;
  pages: string[];
}

export interface ModuleConfig {
  root: string;
  navigationBarTitleText: string;

}
