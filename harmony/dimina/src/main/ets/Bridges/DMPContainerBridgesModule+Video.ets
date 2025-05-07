import { DMPContainerBridgesModule } from './DMPContainerBridgesModule';

import { DMPBridgeCallback } from './DMPTSUtil';
import { DMPMap } from '../Utils/DMPMap';
import { DMPContextUtils } from '../Utils/DMPContextUtils';
import { PhotoPicker } from './PhotoView/PhotoPicker';
import { DMPFileUrlConvertor } from '../Bundle/Util/DMPFileUrlConvertor';
import { CameraPicker } from './PhotoView/CameraPicker';
import { common } from '@kit.AbilityKit';
import { camera } from '@kit.CameraKit';

export class DMPContainerBridgesModuleVideo extends DMPContainerBridgesModule {
  getExportMethods(): string[] {
    return ['chooseMedia'];
  }

  chooseMedia(data: DMPMap, callback: DMPBridgeCallback, webViewId: number) {
    const mediaType: [string] = data.get('mediaType') ?? ["image", "video"];
    const sourceType: [string] = data.get('sourceType') ?? ["album", "camera"];
    const count: number = data.get('count') ?? 9;
    const camera: string = data.get('camera') ?? 'back';
    const maxDuration: number = data.get('maxDuration') ?? 10;

    if (sourceType.length > 1) {
      this.showSelectDialog(webViewId,
        (sourceTypeData) => {
          this.chooseByType(sourceTypeData, mediaType[0], count, "compressed", camera, maxDuration, callback);
        }
      )
    } else {
      const sourceTypeData = sourceType[0]
      this.chooseByType(sourceTypeData, mediaType[0], count, "compressed", camera, maxDuration, callback);
    }
  }

  private chooseByType(sourceType: string, mediaType: string, count: number, sizeType: string, camera: string,
    maxDuration: number, callback: DMPBridgeCallback) {
    if (sourceType === 'album') {
      if (mediaType === 'image') {
        this.chooseImageByAlbum(count, callback)
      } else {
        this.chooseVideoByAlbum(count, callback)
      }
    } else if (sourceType === 'camera') {
      if (mediaType === 'image') {
        this.chooseImageByCamera(camera, callback)
      } else {
        this.chooseVideoByCamera(camera, callback)
      }
    }
  }

  chooseImageByAlbum(count: number, callback: DMPBridgeCallback) {
    let path = DMPContextUtils.getUIAbilityContext().cacheDir + '/chooseImage';
    PhotoPicker.selectPhotos(DMPContextUtils.getUIAbilityContext(), path, count).then((photoModels) => {
      if (photoModels != null) {
        const tempFiles = new Array<Map<string, object>>()
        photoModels.forEach((element) => {
          const vPath = DMPFileUrlConvertor.vPathFromLocalPath(element.localPath)
          const tempFileDic = new Map<string, object>()
          tempFileDic['tempFilePath'] = vPath
          tempFiles.push(tempFileDic)
        })
        const data = new DMPMap()
        data.set('tempFiles', tempFiles);
        data.set('type', 'image');
        this.invokeSuccessCallback(callback, data)
      } else {
        this.invokeFailureCallback(callback, null, '选择照片失败')
      }
    });
  }

  chooseImageByCamera(cameraType: string, callback: DMPBridgeCallback) {
    let path = DMPContextUtils.getUIAbilityContext().cacheDir + '/chooseImage';
    CameraPicker.takePhoto(getContext() as common.UIAbilityContext, path,
      cameraType == "back" ? camera.CameraPosition.CAMERA_POSITION_BACK : camera.CameraPosition.CAMERA_POSITION_FRONT)
      .then((result) => {
        if (result) {
          const tempFiles = new Array<Map<string, object>>()
          const vPath = DMPFileUrlConvertor.vPathFromLocalPath(result.localPath)
          const tempFileDic = new Map<string, object>()
          tempFileDic['tempFilePath'] = vPath
          tempFiles.push(tempFileDic)
          const data = new DMPMap()
          data.set('tempFiles', tempFiles);
          data.set('type', 'image');
          this.invokeSuccessCallback(callback, data)
        } else {
          this.invokeFailureCallback(callback, null, '拍照失败')
        }
      })
  }

  chooseVideoByCamera(cameraType: string, callback: DMPBridgeCallback) {
    let path = DMPContextUtils.getUIAbilityContext().cacheDir + '/chooseImage';
    CameraPicker.takeVideo(getContext() as common.UIAbilityContext, path,
      cameraType == "back" ? camera.CameraPosition.CAMERA_POSITION_BACK : camera.CameraPosition.CAMERA_POSITION_FRONT)
      .then((result) => {
        if (result) {
          const tempFiles = new Array<Map<string, object>>()
          const vPath = DMPFileUrlConvertor.vPathFromLocalPath(result.localPath)
          const tempFileDic = new Map<string, object>()
          tempFileDic['tempFilePath'] = vPath
          tempFiles.push(tempFileDic)
          const data = new DMPMap()
          data.set('tempFiles', tempFiles);
          data.set('type', 'video');
          this.invokeSuccessCallback(callback, data)
        } else {
          this.invokeFailureCallback(callback, null, '拍照失败')
        }
      })
  }

  chooseVideoByAlbum(count: number, callback: DMPBridgeCallback) {
    let path = DMPContextUtils.getUIAbilityContext().cacheDir + '/chooseVideo';
    PhotoPicker.selectVideos(DMPContextUtils.getUIAbilityContext(), path, count).then((photoModels) => {
      if (photoModels != null) {
        const tempFiles = new Array<Map<string, object>>()
        photoModels.forEach((element) => {
          const vPath = DMPFileUrlConvertor.vPathFromLocalPath(element.localPath)
          const tempFileDic = new Map<string, object>()
          tempFileDic['tempFilePath'] = vPath
          tempFiles.push(tempFileDic)
        })
        const data = new DMPMap()
        data.set('tempFiles', tempFiles);
        data.set('type', 'video');
        this.invokeSuccessCallback(callback, data)
      } else {
        this.invokeFailureCallback(callback, null, '选择视频失败')
      }
    });
  }

  showSelectDialog(webViewId: number, onSelect: (type: string) => void) {
    const title = "请选择"
    const color = '#000000'
    const items = ['拍摄', '从相册选择']
    const record = this.app.navigatorManager.getPageRecordById(webViewId)
    if (record?.actionSheetController != null) {
      record.actionSheetController.params = { title: title, color: color, items: items }
      record.actionSheetController.setOnSelectListener((index) => {
        onSelect(items[index] === '拍摄' ? 'camera' : 'album');
      })
      record.actionSheetController.open()
    }
  }
}
