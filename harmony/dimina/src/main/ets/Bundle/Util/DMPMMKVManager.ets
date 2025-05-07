
import { MMKV } from '@ohos/mmkv'
import { DMPMap } from '../../Utils/DMPMap';
import { DMPFileManager } from './DMPFileManager';


export class DMPMMKVManager {
  public mmkv: MMKV;
  private static instance: DMPMMKVManager

  static sharedInstance() {
    if (!DMPMMKVManager.instance) {
      DMPMMKVManager.instance = new DMPMMKVManager();
    }
    return DMPMMKVManager.instance;
  }

  constructor() {
    let sandboxPath = DMPFileManager.sharedInstance().sandboxPath;
    let rootPath = sandboxPath + '/mmkv'
    let cachePath = DMPFileManager.sharedInstance().cacheDir + '/mmkv';
    MMKV.initialize(rootPath, cachePath)

    let mmapID = 'dimina_mmkv_mmap_id';
    let backupRootDir = sandboxPath + '/mmkv_backup'
    this.mmkv = MMKV.getBackedUpMMKVWithID(mmapID, MMKV.SINGLE_PROCESS_MODE, "DIMINA MMKV", backupRootDir);
  }

  encode(key: string, value: number | string | boolean | Date | object): boolean {
    const type = typeof value

    this.mmkv.encodeString(this._genTypeKey(key), type)

    switch (typeof value) {
      case 'boolean': {
        return this.mmkv.encodeBool(key, value)
      }

      case 'number': {
        return this.mmkv.encodeNumber(key, value)
      }

      case 'object': {
        const v = JSON.stringify(value)
        return this.mmkv.encodeString(key, v)
      }

      case 'string': {
        return this.mmkv.encodeString(key, value)
      }

      default:
        return false;
    }
  }


  decode(key: string): DMPMap {
    const result = new DMPMap();
    let value: number | string | boolean | Date | object

    const type = this._getType(key)
    switch (type) {
      case 'boolean': {
        value = this.mmkv.decodeBool(key)
        break;
      }
      case 'number': {
        value = this.mmkv.decodeNumber(key)
        break;
      }
      case 'object': {
        let str:string = this.mmkv.decodeString(key)
        value = JSON.parse(str)
        break;
      }
      case 'string': {
        value = this.mmkv.decodeString(key)
        break;
      }
      default:
        value = '';
        break;
    }

    result.set('value', value);
    result.set('type', type);
    result.set('key', key);

    return result
  }

  remove(key: string) {
    this.mmkv.removeValueForKey(key)
  }

  clear() {
    this.mmkv.clearAll()
  }


  _getType(key: string): string {
    return this.mmkv.decodeString(this._genTypeKey(key));
  }

  _genTypeKey(key: string) {
    return key + '_mMKv7Yp3'
  }

  totalSize(): number {
    return this.mmkv.totalSize()
  }

  keys(): string[] {
    return this.mmkv.getAllKeys()
  }

}