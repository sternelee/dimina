import { util } from '@kit.ArkTS';
import { BusinessError, systemDateTime } from '@kit.BasicServicesKit';
import fs from '@ohos.file.fs';
import { Tags } from '../EventTrack/Tags';
import { DMPLogger } from '../EventTrack/DMPLogger';

export class DMPRawFileUtils {

  static loadFile(context: Context, path: string): string {
    let resourceManager = context.resourceManager;
    try {
      const uint8Array = resourceManager.getRawFileContentSync(path)
      let textDecoder = util.TextDecoder.create('utf-8', { ignoreBOM: true });
      let retStr = textDecoder.decodeToString(uint8Array, { stream: false });
      return retStr
    } catch (error) {
      let code = (error as BusinessError).code;
      let message = (error as BusinessError).message;
      DMPLogger.w(Tags.BUNDLE,`底包不存在：${path}, error code: ${code}, message: ${message}.`);
      return ''
    }
  }

  static copyRawFileToSandBox(context: Context, originPath: string, targetPath: string) {
    let start = systemDateTime.getTime()
    let rawFd = context.resourceManager.getRawFdSync(originPath)
    if (rawFd != null) {
      fs.createStreamSync(targetPath, 'w');
      let targetFile = fs.openSync(targetPath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);
      let bufferSize = rawFd.length < 4096 ? rawFd.length : 4096;
      let buf = new ArrayBuffer(bufferSize);
      let off = 0, len = 0, readLength = 0;

      while (len = fs.readSync(rawFd.fd, buf, { offset: rawFd.offset + off, length: bufferSize })) {
        readLength += len;
        fs.writeSync(targetFile.fd, buf, { offset: off, length: len });
        off = off + len;
        if ((rawFd.length - readLength) < bufferSize) {
          bufferSize = rawFd.length - readLength;
        }
      }
      fs.close(targetFile.fd);
    } else {
      DMPLogger.e(Tags.BUNDLE,`复制出现错误`);
    }
    let end = systemDateTime.getTime()
    DMPLogger.d(Tags.BUNDLE,'复制完成:'+originPath+"耗时："+(end-start));
  }


}