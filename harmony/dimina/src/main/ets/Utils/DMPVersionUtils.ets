import fs from '@ohos.file.fs';
import { DMPLogger } from '../EventTrack/DMPLogger';
import { Tags } from '../EventTrack/Tags';


export class DMPVersionUtil {
  //保留3个版本
  static async clearHistory(cacheVersion: string, dir: string) {
    try {
      let listFile = await fs.listFile(dir);
      if (listFile != null) {
        let filterList = listFile.filter((value) => (value !== 'config.json'))
        filterList.sort((a, b) => DMPVersionUtil.compareVersion(b, a))
        if (filterList.length > 3) {
          for (let i = 3; i < filterList.length; i++) {
            try {
              //重复发同一个版本时，避免删除下次启动的版本
              if (cacheVersion !== filterList[i]) {
                await fs.rmdir(dir + '/' + filterList[i]);
              }
            } catch (e) {
              DMPLogger.e(Tags.BUNDLE, `Failed to remove directory ${filterList[i]}: ${e}`);
            }
          }
        }
      }
    } catch (e) {
      DMPLogger.e(Tags.BUNDLE, `Failed to clear history: ${e}`);
    }
  }

  /**
   * 版本号比较
   *
   * @param version1
   * @param version2
   * @return
   */
  public static compareVersion(version1: string, version2: string): number {
    try {
      if (!version1 || !version2) {
        DMPLogger.e(Tags.BUNDLE, "compareVersion version is undefined")
        return 0
      }
      if (version1 === version2) {
        return 0;
      }
      //处理第四位_情况
      version1 = version1.replace(/_/g, '.');
      version2 = version2.replace(/_/g, '.');

      const version1Array: string[] = version1.split('.'); // 转义
      const version2Array: string[] = version2.split('.');

      let index = 0;
      // 获取最小长度值
      const minLen = Math.min(version1Array.length, version2Array.length);
      let diff = 0;
      // 循环判断每位的大小
      while (
        index < minLen &&
          (diff =
            parseInt(version1Array[index], 10) -
            parseInt(version2Array[index], 10)) === 0
      ) {
        index++;
      }
      if (diff === 0) {
        // 如果位数不一致，比较多余位数
        for (let i = index; i < version1Array.length; i++) {
          if (parseInt(version1Array[i], 10) > 0) {
            return 1;
          }
        }

        for (let i = index; i < version2Array.length; i++) {
          if (parseInt(version2Array[i], 10) > 0) {
            return -1;
          }
        }
        return 0;
      } else {
        return diff > 0 ? 1 : -1;
      }
    } catch (e) {
      return 0;
    }
  }
}