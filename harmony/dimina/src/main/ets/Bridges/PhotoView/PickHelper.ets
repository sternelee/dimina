import fs from '@ohos.file.fs';
import { fileUri } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { AssetModel } from './AssetModel';
import { DMPLogger } from '../../EventTrack/DMPLogger';

export class PickHelper {
  /**
   * 根据相机相册返回的uri生成 AssetModel
   *
   * @param uris 图片uri数组
   * @param toDir 要copy到的本地路径
   * @returns 返回 AssetModels
   */
  static async makeAssetModels(uris: Array<string>, toDir: string): Promise<Array<AssetModel>> {
    let access = await fs.access(toDir)
    if (access == false) {
      await fs.mkdir(toDir).catch((err: BusinessError) => {
        DMPLogger.e(`[PhotosUtil] mkdir error: ${JSON.stringify(err)}`)
      })
    }

    let models = new Array<AssetModel>();

    for (let index = 0; index < uris.length; index++) {
      const uri = uris[index];
      const fileName = uri.split('/').pop() ?? "default.jpg"
      let localPath = toDir + '/' + fileName;

      await PickHelper.copyUriAssetToLocal(uri, localPath)
      let model = await PickHelper.buildAssetModel(fileName, uri, localPath)

      models.push(model);
    }

    return models;
  }

  private static async buildAssetModel(fileName: string, uri: string, localPath: string) {
    let model = new AssetModel();
    model.name = fileName!;
    model.uri = uri;
    model.localPath = localPath;
    return model
  }

  private static async copyUriAssetToLocal(uri: string, localPath: string) {
    let access = await fs.access(localPath)
    if (access) {
      await fs.unlink(localPath).catch((err: BusinessError) => {
        DMPLogger.e("[PhotosUtil] Photo unlink error = " + JSON.stringify(err));
      })
    }
    // 注意uri 和 Path的区别，文档里参数带uri的才能使用uri参数
    await fs.copy(uri, fileUri.getUriFromPath(localPath)).catch((err: BusinessError) => {
      DMPLogger.e("[PhotosUtil] Photo copy error = " + JSON.stringify(err));
    })
  }
}