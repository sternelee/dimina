import { DMPContainerBridgesModule } from './DMPContainerBridgesModule';

import { DMPBridgeCallback } from './DMPTSUtil';
import { DMPMap } from '../Utils/DMPMap';
import { DMPContextUtils } from '../Utils/DMPContextUtils';
import { PhotoPicker } from './PhotoView/PhotoPicker';
import { DMPFileUrlConvertor } from '../Bundle/Util/DMPFileUrlConvertor';
import { CameraPicker } from './PhotoView/CameraPicker';
import { common } from '@kit.AbilityKit';
import { camera } from '@kit.CameraKit';
import media from '@ohos.multimedia.media';
import fs from '@ohos.file.fs';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { fileUri } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';

export class DMPContainerBridgesModuleVideo extends DMPContainerBridgesModule {
  getExportMethods(): string[] {
    return ['chooseMedia', 'chooseVideo', 'getVideoInfo', 'saveVideoToPhotosAlbum', 'compressVideo'];
  }

  chooseVideo(data: DMPMap, callback: DMPBridgeCallback, webViewId: number) {
    const sourceType: [string] = data.get('sourceType') ?? ["album", "camera"];
    const count: number = data.get('count') ?? 9;
    const camera: string = data.get('camera') ?? 'back';
    const maxDuration: number = data.get('maxDuration') ?? 10;

    if (sourceType.length > 1) {
      this.showSelectDialog(webViewId,
        (sourceTypeData) => {
          this.chooseVideoBySourceType(sourceTypeData, count, camera, maxDuration, callback)
        }
      )
    } else {
      const sourceTypeData = sourceType[0]
      this.chooseVideoBySourceType(sourceTypeData, count, camera, maxDuration, callback)
    }
  }

  chooseVideoBySourceType(sourceType: string, count: number, cameraType: string, maxDuration: number,
    callback: DMPBridgeCallback) {
    if (sourceType === 'album') {
      let path = DMPContextUtils.getUIAbilityContext().cacheDir + '/chooseVideo';
      PhotoPicker.selectVideos(DMPContextUtils.getUIAbilityContext(), path, count).then((photoModels) => {
        if (photoModels != null) {
          this.completeChooseVideo(photoModels[0].localPath, callback)
        } else {
          this.invokeFailureCallback(callback, null, '选择视频失败')
        }
      });
    } else if (sourceType === 'camera') {
      let path = DMPContextUtils.getUIAbilityContext().cacheDir + '/chooseVideo';
      CameraPicker.takeVideo(getContext() as common.UIAbilityContext, path, maxDuration,
        cameraType == "back" ? camera.CameraPosition.CAMERA_POSITION_BACK : camera.CameraPosition.CAMERA_POSITION_FRONT)
        .then((result) => {
          if (result) {
            this.completeChooseVideo(result.localPath, callback)
          } else {
            this.invokeFailureCallback(callback, null, '拍照失败')
          }
        })
    }
  }

  async getVideoInfo(data: DMPMap, callback: DMPBridgeCallback) {
    const src = data.getString('src') ?? '';
    const localPath = DMPFileUrlConvertor.localPathFromVPath(src);
    try {
      const result = await this.videoInfo(localPath);
      result.set('errMsg', 'getVideoInfo:ok');
      this.invokeSuccessCallback(callback, result, true);
    } catch (error) {
      this.invokeFailureCallback(callback, null, `getVideoInfo:fail ${error}`);
    }
  }

  async saveVideoToPhotosAlbum(data: DMPMap, callback: DMPBridgeCallback) {
    const filePath = DMPFileUrlConvertor.localPathFromVPath(data.getString('filePath') ?? '');
    if (!filePath || !fs.accessSync(filePath)) {
      this.invokeFailureCallback(callback, null, 'saveVideoToPhotosAlbum:fail invalid filePath');
      return;
    }
    try {
      const helper = photoAccessHelper.getPhotoAccessHelper(DMPContextUtils.getUIAbilityContext());
      const sourceUri = fileUri.getUriFromPath(filePath);
      const configs: Array<photoAccessHelper.PhotoCreationConfig> = [{
        fileNameExtension: this.fileExtension(filePath, 'mp4'),
        photoType: photoAccessHelper.PhotoType.VIDEO,
        subtype: photoAccessHelper.PhotoSubtype.DEFAULT,
      }];
      const destinations = await helper.showAssetsCreationDialog([sourceUri], configs);
      if (destinations.length === 0) {
        throw new Error('cancel');
      }
      const source = fs.openSync(filePath, fs.OpenMode.READ_ONLY);
      const destination = fs.openSync(destinations[0], fs.OpenMode.WRITE_ONLY);
      try {
        await fs.copyFile(source.fd, destination.fd);
      } finally {
        fs.closeSync(source);
        fs.closeSync(destination);
      }
      const result = new DMPMap();
      result.set('errMsg', 'saveVideoToPhotosAlbum:ok');
      this.invokeSuccessCallback(callback, result, true);
    } catch (error) {
      this.invokeFailureCallback(callback, null, `saveVideoToPhotosAlbum:fail ${error}`);
    }
  }

  async compressVideo(data: DMPMap, callback: DMPBridgeCallback) {
    const src = DMPFileUrlConvertor.localPathFromVPath(data.getString('src') ?? '');
    if (!src || !fs.accessSync(src)) {
      this.invokeFailureCallback(callback, null, 'compressVideo:fail invalid src');
      return;
    }

    const context = DMPContextUtils.getUIAbilityContext();
    const outputPath = `${context.tempDir}/compressed_video_${Date.now()}.mp4`;
    const source = fs.openSync(src, fs.OpenMode.READ_ONLY);
    const destination = fs.openSync(outputPath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
    let transcoder: media.AVTranscoder | undefined;
    try {
      const metadata = await this.readMetadata(src);
      const resolution = data.getNumber('resolution') ?? 1;
      if (resolution <= 0 || resolution > 1) {
        throw new Error('invalid resolution');
      }
      const quality = data.getString('quality') ?? 'medium';
      const requestedBitrate = data.getNumber('bitrate');
      const qualityBitrate = quality === 'low' ? 1000000 : quality === 'high' ? 4000000 : 2000000;
      const width = Math.floor(Number(metadata.videoWidth ?? '0') * resolution);
      const height = Math.floor(Number(metadata.videoHeight ?? '0') * resolution);
      const config: media.AVTranscoderConfig = {
        fileFormat: media.ContainerFormatType.CFT_MPEG_4,
        videoCodec: media.CodecMimeType.VIDEO_AVC,
        videoBitrate: requestedBitrate && requestedBitrate > 0 ? requestedBitrate * 1000 : qualityBitrate,
      };
      if (width >= 240 && height >= 240) {
        config.videoFrameWidth = width;
        config.videoFrameHeight = height;
      }

      transcoder = await media.createAVTranscoder();
      transcoder.fdSrc = { fd: source.fd, offset: 0, length: fs.statSync(src).size };
      transcoder.fdDst = destination.fd;
      await new Promise<void>((resolve, reject) => {
        transcoder!.on('complete', () => resolve());
        transcoder!.on('error', (error: BusinessError) => reject(error));
        transcoder!.prepare(config).then(() => transcoder!.start()).catch((error: BusinessError) => reject(error));
      });

      const result = new DMPMap();
      result.set('tempFilePath', DMPFileUrlConvertor.vPathFromLocalPath(outputPath));
      result.set('size', Math.ceil(fs.statSync(outputPath).size / 1024));
      result.set('errMsg', 'compressVideo:ok');
      this.invokeSuccessCallback(callback, result, true);
    } catch (error) {
      if (fs.accessSync(outputPath)) {
        fs.unlinkSync(outputPath);
      }
      this.invokeFailureCallback(callback, null, `compressVideo:fail ${error}`);
    } finally {
      if (transcoder) {
        await transcoder.release();
      }
      fs.closeSync(source);
      fs.closeSync(destination);
    }
  }

  private async completeChooseVideo(localPath: string, callback: DMPBridgeCallback) {
    try {
      const info = await this.videoInfo(localPath);
      info.set('tempFilePath', DMPFileUrlConvertor.vPathFromLocalPath(localPath));
      info.set('size', fs.statSync(localPath).size);
      info.set('errMsg', 'chooseVideo:ok');
      this.invokeSuccessCallback(callback, info, true);
    } catch (error) {
      this.invokeFailureCallback(callback, null, `chooseVideo:fail ${error}`);
    }
  }

  private async videoInfo(localPath: string): Promise<DMPMap> {
    const metadata = await this.readMetadata(localPath);
    const result = new DMPMap();
    result.set('duration', Number(metadata.duration ?? '0') / 1000);
    result.set('width', Number(metadata.videoWidth ?? '0'));
    result.set('height', Number(metadata.videoHeight ?? '0'));
    result.set('orientation', this.orientation(Number(metadata.videoOrientation ?? '0')));
    result.set('type', this.fileExtension(localPath, 'mp4'));
    result.set('size', Math.ceil(fs.statSync(localPath).size / 1024));
    result.set('bitrate', 0);
    result.set('fps', 0);
    return result;
  }

  private async readMetadata(localPath: string): Promise<media.AVMetadata> {
    if (!localPath || !fs.accessSync(localPath)) {
      throw new Error('invalid file path');
    }
    const source = fs.openSync(localPath, fs.OpenMode.READ_ONLY);
    const extractor = await media.createAVMetadataExtractor();
    try {
      extractor.fdSrc = { fd: source.fd, offset: 0, length: fs.statSync(localPath).size };
      return await extractor.fetchMetadata();
    } finally {
      await extractor.release();
      fs.closeSync(source);
    }
  }

  private orientation(degrees: number): string {
    return degrees === 90 ? 'right' : degrees === 180 ? 'down' : degrees === 270 ? 'left' : 'up';
  }

  private fileExtension(path: string, fallback: string): string {
    const cleanPath = path.split('?')[0];
    const dot = cleanPath.lastIndexOf('.');
    return dot >= 0 ? cleanPath.substring(dot + 1).toLowerCase() : fallback;
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
        this.chooseVideoByCamera(camera, maxDuration, callback)
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

  chooseVideoByCamera(cameraType: string, maxDuration: number, callback: DMPBridgeCallback) {
    let path = DMPContextUtils.getUIAbilityContext().cacheDir + '/chooseImage';
    CameraPicker.takeVideo(getContext() as common.UIAbilityContext, path, maxDuration,
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
