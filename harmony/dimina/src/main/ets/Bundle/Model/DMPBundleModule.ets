
import { DMPMap } from '../../Utils/DMPMap';

export enum DMPModuleDownloadType {
  Now = 0, //同步下载
  Lazy = 1, //懒加载
  PREV = 2, //预下载

}

export function intToDMPModuleDownloadType(value: number): DMPModuleDownloadType | null {
  const enumValues = Object.values(DMPModuleDownloadType) as number[];
  if (enumValues.includes(value)) {
    return value as DMPModuleDownloadType;
  }
  return null;
}

//子模块信息
export class DMPBundleModule {
  public id: string = '';
  public name: string = '';
  public md5: string = '';
  public url: string = '';
  public key: string = '';
  public version: string = '';
  public channel: string = '';
  // 是否是预下载  预下载优先级是1，默认是0（高优先级）
  public preload: boolean = false;
  public lazyDownload?: DMPModuleDownloadType;
  //保存路径，下载时需要
  private _savePath: string = '';

  public set savePath(value: string) {
    this._savePath = value;
  }

  public zipName(): string {
    return this.name + '.zip'
  }

  public encodedObject(): DMPMap {
    let result: DMPMap = new DMPMap();
    result.set('module_id', this.id ?? '');
    result.set('module_name', this.name ?? '');
    result.set('url', this.url ?? '');
    result.set('md5', this.md5 ?? '');
    result.set('key', this.key ?? '');
    result.set('lazy_download', this.lazyDownload);
    result.set('version', this.version ?? '');
    result.set('channel', this.channel ?? '');
    return result;
  }


  public static decodeWithDictionary(dictionary: DMPMap): DMPBundleModule | null {
    if (!dictionary) {
      return null;
    }
    let module = new DMPBundleModule();
    module.name = dictionary.get('module_name');
    module.md5 = dictionary.get('md5');
    module.key = dictionary.get('key');
    module.url = dictionary.get('url');
    module.channel = dictionary.get('channel') ?? '';
    module.version = dictionary.get('version');
    module.lazyDownload = dictionary.get('lazy_download') ?? 0;
    module.id = dictionary.get('module_id');
    return module;
  }

  public getRootPath() {
    return this._savePath;
  }
}
