import picker from '@ohos.multimedia.cameraPicker';
import camera from '@ohos.multimedia.camera';
import common from '@ohos.app.ability.common';
import { BusinessError } from '@ohos.base';
import { AssetModel } from './AssetModel';
import { PickHelper } from './PickHelper';
import { DMPLogger } from '../../EventTrack/DMPLogger';

export class CameraPicker {
  /**
   * 调用系统相机拍照（无权限）
   *
   * @param context 上下文
   * @param toDir 存放位置，会把照片copy过去
   * @param frontCamera 是否使用前置相机
   * @returns 返回AssetModel
   */
  public static async takePhoto(context: common.UIAbilityContext, localDir: string, cameraPos?: camera.CameraPosition): Promise<AssetModel | null> {
    let pickerProfile: picker.PickerProfile = {
      cameraPosition: (cameraPos != undefined ? cameraPos : camera.CameraPosition.CAMERA_POSITION_BACK)
    };
    return picker.pick(context, [picker.PickerMediaType.PHOTO], pickerProfile).then(async (pickerResult: picker.PickerResult) => {
      if (pickerResult.resultCode == 0) {
        let uri = pickerResult.resultUri;
        let models = await PickHelper.makeAssetModels([uri], localDir)
        return models[0]
      } else {
        DMPLogger.e(`[CameraPicker] pickerResult resultCode = ${pickerResult.resultCode}`);
        return null
      }
    }).catch((err: BusinessError) => {
      DMPLogger.e("[CameraPicker] takePhoto error = " + JSON.stringify(err));
      return null;
    });
  }

  /**
   * 调用系统相机录像（无权限）
   *
   * @param context 上下文
   * @param toDir 存放位置，会把照片copy过去
   * @param frontCamera 是否使用前置相机
   * @param maxDuration 录制的最大时长
   * @returns 返回AssetModel
   */
  public static async takeVideo(context: common.UIAbilityContext, localDir: string, maxDuration?: number, cameraPos?: camera.CameraPosition) {
    let pickerProfile: picker.PickerProfile = {
      cameraPosition: (cameraPos != undefined ? cameraPos : camera.CameraPosition.CAMERA_POSITION_BACK),
      videoDuration: maxDuration
    };
    return picker.pick(context, [picker.PickerMediaType.VIDEO], pickerProfile).then(async (pickerResult: picker.PickerResult) => {
      if (pickerResult.resultCode == 0) {
        let uri = pickerResult.resultUri;
        let models = await PickHelper.makeAssetModels([uri], localDir)
        return models[0]
      } else {
        DMPLogger.e(`[CameraPicker] pickerResult resultCode = ${pickerResult.resultCode}`);
        return null
      }
    }).catch((err: BusinessError) => {
      DMPLogger.e("[CameraPicker] takeVideo error = " + JSON.stringify(err));
      return null;
    });
  }
}
