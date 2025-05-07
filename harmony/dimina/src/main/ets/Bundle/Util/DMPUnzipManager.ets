
import zlib from '@ohos.zlib';
import { DMPLogger } from '../../EventTrack/DMPLogger';

export class DMPUnzipManager {
  static async unzipFileAtPathAsync(zipPath: string, targetPath: string): Promise<boolean> {
    return new Promise<boolean>((resolve, reject) => {
      DMPUnzipManager.unzipFileAtPath(zipPath, targetPath, (path, success, error) => {
        resolve(success);
        DMPLogger.d("unzipFileAtPathAsync unzip status=" + success)
      });
    });
  }

  static unzipFileAtPath(path: string, toDestination: string,
    completionHandler: (path: string, succeeded: boolean, error: Error | null) => void): void {
    try {
      zlib.decompressFile(path, toDestination, {
        level: zlib.CompressLevel.COMPRESS_LEVEL_DEFAULT_COMPRESSION,
        memLevel: zlib.MemLevel.MEM_LEVEL_DEFAULT,
        strategy: zlib.CompressStrategy.COMPRESS_STRATEGY_DEFAULT_STRATEGY
      }, (errData) => {
        if (errData !== null) {
          DMPLogger.e(`unzipFileAtPath errData is errCode:${errData.code}  message:${errData.message}`);
          if (completionHandler) {
            completionHandler(toDestination, false, errData);
          }
        } else {
          if (completionHandler) {
            completionHandler(toDestination, true, null);
          }
        }
      })
    } catch (errData) {
      if (completionHandler) {
        completionHandler(toDestination, false, errData);
      }
      DMPLogger.e(`errData is errCode:${errData.code}  message:${errData.message}`);
    }
  }

  static unzipFiles(zipFiles: Array<string>, toDestination: string,
    completionHandler: (path: string, succeeded: boolean, error: Error | null) => void): void {
    if (zipFiles.length === 0) {
      if (completionHandler) {
        completionHandler(toDestination, false, null);
      }
    }
    let finalSuccess = true;
    let count = 0;
    for (let index = 0; index < zipFiles.length; index++) {
      const zipFile = zipFiles[index];
      const name: string = zipFile.substring(zipFile.lastIndexOf('/') + 1, zipFile.lastIndexOf('.'));
      const dest = toDestination + '/' + name;
      DMPUnzipManager.unzipFileAtPath(zipFile, dest, (path: string, success: Boolean, error: Error | null) => {
        count++;
        if (!success) {
          finalSuccess = false;
        }
        if (count === zipFile.length) {
          //执行completion
          if (completionHandler) {
            completionHandler(toDestination, finalSuccess, null);
          }
        }
      })
    }
  }
}