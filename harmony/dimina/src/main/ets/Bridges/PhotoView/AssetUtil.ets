import image from '@ohos.multimedia.image';
import { fileIo } from '@kit.CoreFileKit';
import fileUri from '@ohos.file.fileuri';
import { AssetModel, AssetExtType } from './AssetModel';
import { JSON, buffer } from '@kit.ArkTS';
import { DMPLogger } from '../../EventTrack/DMPLogger';

export class AssetUtil {

  /**
   * 获取图片imageSource
   *
   * @param asset 图片
   * @returns 返回imageSource
   */
  static getAssetSource(asset: string | AssetModel) {
    let path = typeof asset == 'string' ? asset : asset.localPath;
    const imageSource = image.createImageSource(path);
    return imageSource
  }

  /**
   * 获取图片size
   *
   * @param asset 图片
   * @returns 返回图片size
   */
  static async getAssetSize(asset: string | AssetModel) {
    const imageSource = AssetUtil.getAssetSource(asset);
    const imageInfo = await imageSource.getImageInfo()
    await imageSource.release()
    return imageInfo.size
  }

  /**
   * 按图片大小生成ArrayBuffer
   *
   * @param asset 图片
   * @returns 返回ArrayBuffer
   */
  static async makeAssetArrayBuffer(asset: string | AssetModel) {
    let assetSize = await AssetUtil.getAssetSize(asset)
    let bufferSize = assetSize.width * assetSize.height * 4
    return new ArrayBuffer(bufferSize)
  }

  /**
   * 按比例缩放图片
   *
   * @param asset 图片
   * @param scaleX 高度的缩放倍数。
   * @param scaleX 高度的缩放倍数。
   * @param filePath 操作后图片存储位置
   * @returns 返回JPEG图片AssetModel
   */
  static async scaleAsset(asset: string | AssetModel, scaleX: number, scaleY: number, filePath?: string): Promise<AssetModel> {
    DMPLogger.i('[AssetUtil]',`scaleAsset asset: ${(typeof asset == 'string' ? asset : asset.localPath)}, scaleX: ${scaleX}, scaleY: ${scaleY}, filePath: ${filePath}`);
    let path = filePath ? filePath : AssetUtil.getDefaultFilePath("_scale", asset)
    return AssetUtil.modifyPixelMapAction(asset, 100, path, async (pixelMap: image.PixelMap)=>{
      await pixelMap.scale(scaleX, scaleY)
    })
  }

  /**
   * 变换图片
   *
   * @param asset 图片
   * @param translateX 区域横坐标
   * @param translateY 区域纵坐标
   * @param filePath 操作后图片存储位置
   * @returns 返回 JPEG图片AssetModel
   */
  static async translateAsset(asset: string | AssetModel, translateX: number, translateY: number, filePath?: string): Promise<AssetModel> {
    DMPLogger.i('[AssetUtil]',`translateAsset asset: ${(typeof asset == 'string' ? asset : asset.localPath)}, translateX: ${translateX}, translateY: ${translateY}, filePath: ${filePath}`);
    let path = filePath ? filePath : AssetUtil.getDefaultFilePath("_translate", asset)
    return AssetUtil.modifyPixelMapAction(asset, 100, path, async (pixelMap: image.PixelMap)=>{
      await pixelMap.translate(translateX, translateY)
    })
  }

  /**
   * 翻转图片
   *
   * @param asset 图片
   * @param horizontal 水平翻转
   * @param vertical 垂直翻转
   * @param filePath 操作后图片存储位置
   * @returns 返回 JPEG图片的AssetModel
   */
  static async flipAsset(asset: string | AssetModel, horizontal: boolean, vertical: boolean, filePath?: string): Promise<AssetModel> {
    DMPLogger.i('[AssetUtil]',`flipAsset asset: ${(typeof asset == 'string' ? asset : asset.localPath)}, horizontal: ${horizontal}, vertical: ${vertical}, filePath: ${filePath}`);
    let path = filePath ? filePath : AssetUtil.getDefaultFilePath("_rotate", asset)
    return AssetUtil.modifyPixelMapAction(asset, 100, path, async (pixelMap: image.PixelMap)=>{
      await pixelMap.flip(horizontal, vertical)
    })
  }

  /**
   * 旋转图片
   *
   * @param asset 图片
   * @param angle 旋转角度
   * @param filePath 操作后图片存储位置
   * @returns 返回 JPEG图片的AssetModel
   */
  static async rotateAsset(asset: string | AssetModel, angle: number, filePath?: string): Promise<AssetModel> {
    DMPLogger.i('[AssetUtil]',`rotateAsset asset: ${(typeof asset == 'string' ? asset : asset.localPath)}, angle: ${angle}, filePath: ${filePath}`);
    let path = filePath ? filePath : AssetUtil.getDefaultFilePath("_flip", asset)
    return AssetUtil.modifyPixelMapAction(asset, 100, path, async (pixelMap: image.PixelMap)=>{
      await pixelMap.rotate(angle)
    })
  }

  /**
   * 裁剪图片
   *
   * @param asset 图片
   * @param region 裁剪范围
   * @param filePath 操作后图片存储位置
   * @returns 返回 JPEG图片的AssetModel
   */
  static async cropAsset(asset: string | AssetModel, region: image.Region, filePath?: string): Promise<AssetModel> {
    DMPLogger.i('[AssetUtil]',`cropAsset asset: ${(typeof asset == 'string' ? asset : asset.localPath)}, region: ${JSON.stringify(region)}, filePath: ${filePath}`);
    let path = filePath ? filePath : AssetUtil.getDefaultFilePath("_crop", asset)
    return AssetUtil.modifyPixelMapAction(asset, 100, path, async (pixelMap: image.PixelMap)=>{
      await pixelMap.crop(region)
    })
  }

  /**
   * packing压缩(只支持JPEG,大小不变，降低质量)
   *
   * @param asset 图片
   * @param quality 图片质量参数
   * @returns 返回JPEG图片AssetModel
   */
  static async packingAsset(asset: string | AssetModel, quality: number, filePath?: string): Promise<AssetModel> {
    DMPLogger.i('[AssetUtil]',`packingAsset asset: ${(typeof asset == 'string' ? asset : asset.localPath)}, quality: ${quality}, filePath: ${filePath}`);
    // 只有jpeg能降低图片质量！
    const targetPath = AssetUtil.formatToJpegPath('_packing', asset, filePath)
    return AssetUtil.modifyPixelMapAction(asset, quality, targetPath)
  }

  /**
   * 压缩图片（只支持JPEG,先尝试降低质量，不行就缩放图片）
   *
   * @param asset 图片
   * @param maxSize 允许的最大size (单位KB)
   * @param filePath 操作后图片存储位置
   * @returns 返回 JPEG图片的AssetModel
   */
  static async compressedAsset(asset: string | AssetModel, maxSize: number, filePath?: string): Promise<AssetModel> {
    DMPLogger.i('[AssetUtil]',`compressedAsset asset: ${(typeof asset == 'string' ? asset : asset.localPath)}, maxSize: ${maxSize}, filePath: ${filePath}`);
    const targetPath = AssetUtil.formatToJpegPath('_compressed', asset, filePath)
    let result = new AssetModel();
    try {
      const pixelMap = await AssetUtil.getAssetPixelMap(asset)
      result = await AssetUtil.compressedImage(pixelMap, maxSize, targetPath)
      await pixelMap.release()
    } catch (err) {
      DMPLogger.e('[AssetUtil]',`failed!, asset: ${(typeof asset == 'string' ? asset : asset.localPath)}, error message: ${err.message}, error code: ${err.code}`);
    }
    return result
  }

  static formatToJpegPath(tag: string, asset: string | AssetModel, filePath?: string): string {
    let path = filePath ? filePath : (typeof asset == 'string' ? asset : asset.localPath)
    let fileExt = '.' + path.split('.').pop()
    if (filePath) {
      return path.replace(fileExt, '.jpeg')
    } else {
      return path.replace(fileExt, tag + '.jpeg')
    }
  }

  /**
   * 读取图片并转为base64编码
   *
   * @param base64Str 图片的base64字符串
   * @param filePath 操作后图片存储位置
   * @param base64编码后的图片
   */
  static async getAssetBase64(asset: string | AssetModel, justAssetData?: boolean): Promise<string> {
    let buf: buffer.Buffer
    const path = typeof asset == 'string' ? asset : asset.localPath
    const extType = AssetUtil.getAssetExtTypeFromPath(path)
    if (asset instanceof AssetModel && asset.data) {
      buf = buffer.from(asset.data!);
    } else {
      const pixelMap = await AssetUtil.getAssetPixelMap(asset)
      const data: ArrayBuffer = await AssetUtil.packingPixelMap(extType, pixelMap, 100)
      buf = buffer.from(data);
    }

    let assetBase64 = buf.toString('base64', 0, buf.length)
    if (justAssetData == true) {
      return assetBase64
    }

    let extTag = 'data:image/jpeg;base64,'
    if (extType == AssetExtType.Png) {
      extTag = 'data:image/png;base64,'
    } else if (extType == AssetExtType.Webp) {
      extTag = 'data:image/webp;base64,'
    } else {
      extTag = 'data:image/jpeg;base64,'
    }

    return extTag + assetBase64
  }

  /**
   * Base64字符串转为图片并保存
   *
   * @param base64Str 图片的base64字符串
   * @param filePath 操作后图片存储位置
   */
  static async saveAssetBase64(base64Str: string, filePath: string): Promise<void> {
    const reg = new RegExp("data:image/\\w+;base64,")
    const base64 = base64Str.replace(reg, "");
    const dataBuffer = buffer.from(base64, 'base64')
    await AssetUtil.saveAssetData(dataBuffer.buffer, filePath)
  }

  /**
   * 图片保存
   *
   * @param imageData 图片ArrayBuffer
   * @param filePath 操作后图片存储位置
   */
  static async saveAssetData(imageData: ArrayBuffer, filePath: string): Promise<void> {
    const context: Context = getContext();
    // 定义要保存的压缩图片uri。afterCompressiona.jpeg表示压缩后的图片。
    const compressedImageUri: string = filePath;
    try {
      const res = fileIo.accessSync(compressedImageUri);
      if (res) {
        // 如果图片afterCompressiona.jpeg已存在，则删除
        fileIo.unlinkSync(compressedImageUri);
      }
    } catch (err) {
      DMPLogger.e(`[AssetUtil] saveAssetData failed with error message: ${err.message}, error code: ${err.code}`);
    }
    // 知识点：保存图片。获取最终图片压缩数据compressedImageData，保存图片。
    // 压缩图片数据写入文件
    const file: fileIo.File = fileIo.openSync(compressedImageUri, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
    fileIo.writeSync(file.fd, imageData);
    fileIo.closeSync(file);
  }

  // packing压缩(大小不变降低质量，JPEG)
  static async packingJPEGPixelMap(sourcePixelMap: image.PixelMap, quality: number): Promise<ArrayBuffer> {
    return AssetUtil.packingPixelMap(AssetExtType.Jpeg, sourcePixelMap, quality)
  }


  static async packingPixelMap(extType: AssetExtType, sourcePixelMap: image.PixelMap, quality: number): Promise<ArrayBuffer> {
    const imagePackerApi = image.createImagePacker();
    let format: string = "image/jpeg"
    if (extType == AssetExtType.Jpeg) {
      format = "image/jpeg"
    } if (extType == AssetExtType.Png) {
      format = "image/png"
      quality = 100;
    } if (extType == AssetExtType.Png) {
      format = "image/webp"
      quality = 100;
    }
    const packOpts: image.PackingOption = { format: format, quality: quality };
    const data: ArrayBuffer = await imagePackerApi.packing(sourcePixelMap, packOpts);
    await imagePackerApi.release()
    return data;
  }

  // 默认图片路径
  static getDefaultFilePath(tag: string, asset: string | AssetModel): string {
    let assetPath = typeof asset == 'string' ? asset : asset.localPath;
    let fileExt = '.' + assetPath.split('.').pop()
    return assetPath.replace(fileExt, (tag + fileExt))
  }

  // 从路径中获取图片扩展名
  static getAssetExtTypeFromPath(path: string): AssetExtType {
    let fileExt = '.' + path.split('.').pop()
    if (fileExt.toLowerCase() == 'png') {
      return AssetExtType.Png
    } else if (fileExt.toLowerCase() == 'webp') {
      return AssetExtType.Webp
    } else {
      return AssetExtType.Jpeg
    }
  }

  static async getAssetPixelMap(asset: string | AssetModel) {
    const imageSource = AssetUtil.getAssetSource(asset);
    const decodingOptions: image.DecodingOptions = {
      editable: true, // 是否可编辑。当取值为false时，图片不可二次编辑，如crop等操作将失败。
      desiredPixelFormat: 3, // 解码的像素格式。3表示RGBA_8888 （默认就是 BGRA_8888）
    }
    const pixelMap = await imageSource.createPixelMap(decodingOptions)
    await imageSource.release()
    return pixelMap;
  }

  // 修改图片
  static async modifyPixelMapAction(asset: string | AssetModel, quality: number, filePath: string, action?: (pixelMap: image.PixelMap) => void): Promise<AssetModel> {
    DMPLogger.i('[AssetUtil]',`modifyPixelMapAction asset: ${(typeof asset == 'string' ? asset : asset.localPath)}, quality: ${quality}, filePath: ${filePath}`);
    let result = new AssetModel();
    try {
      const pixelMap = await AssetUtil.getAssetPixelMap(asset)
      if (action) {
        await action(pixelMap)
      }
      let extType = AssetUtil.getAssetExtTypeFromPath(filePath)
      const data: ArrayBuffer = await AssetUtil.packingPixelMap(extType, pixelMap, quality)
      await pixelMap.release()

      await AssetUtil.saveAssetData(data, filePath);

      result.name = filePath.split('/').pop()!
      result.uri = fileUri.getUriFromPath(filePath);
      result.localPath = filePath;
      result.data = data;
      result.dataLength = data.byteLength;
    } catch (err) {
      DMPLogger.e('[AssetUtil]',`failed!, asset: ${(typeof asset == 'string' ? asset : asset.localPath)}, error message: ${err.message}, error code: ${err.code}`);
    } finally {
      DMPLogger.i('[AssetUtil]',`modifyPixelMapAction asset: ${(typeof asset == 'string' ? asset : asset.localPath)}, result: ${JSON.stringify(result)}`);
      return result;
    }
  }
  /**
   * 图片压缩，保存
   *
   * @param sourcePixelMap：原始待压缩图片的PixelMap对象
   * @param maxCompressedImageSize：指定图片的压缩目标大小，单位kb
   * @param filePath 压缩后存储位置
   * @returns compressedImageInfo：返回最终压缩后的图片信息
   */
  static async compressedImage(sourcePixelMap: image.PixelMap, maxCompressedImageSize: number, filePath: string): Promise<AssetModel> {
    // 创建图像编码ImagePacker对象
    const imagePackerApi = image.createImagePacker();
    const IMAGE_QUALITY = 0;
    const packOpts: image.PackingOption = { format: "image/jpeg", quality: IMAGE_QUALITY };
    // 通过PixelMap进行编码。compressedImageData为打包获取到的图片文件流。
    let compressedImageData: ArrayBuffer = await imagePackerApi.packing(sourcePixelMap, packOpts);
    // 压缩目标图像字节长度
    const maxCompressedImageByte = maxCompressedImageSize * 1024;
    // 图片压缩。先判断设置图片质量参数quality为0时，packing能压缩到的图片最小字节大小是否满足指定的图片压缩大小。如果满足，则使用packing方式二分查找最接近指定图片压缩目标大小的quality来压缩图片。如果不满足，则使用scale对图片先进行缩放，采用while循环每次递减0.4倍缩放图片，再用packing（图片质量参数quality设置0）获取压缩图片大小，最终查找到最接近指定图片压缩目标大小的缩放倍数的图片压缩数据。
    if (maxCompressedImageByte > compressedImageData.byteLength) {
      // 使用packing二分压缩获取图片文件流
      compressedImageData =
        await AssetUtil.packingCompressedImage(compressedImageData, sourcePixelMap, IMAGE_QUALITY, maxCompressedImageByte);
    } else {
      // 使用scale对图片先进行缩放，采用while循环每次递减0.4倍缩放图片，再用packing（图片质量参数quality设置0）获取压缩图片大小，最终查找到最接近指定图片压缩目标大小的缩放倍数的图片压缩数据
      let imageScale = 1;
      const REDUCE_SCALE = 0.4;
      // 判断压缩后的图片大小是否大于指定图片的压缩目标大小，如果大于，继续降低缩放倍数压缩。
      while (compressedImageData.byteLength > maxCompressedImageByte) {
        if (imageScale > 0) {
          // 性能知识点: 由于scale会直接修改图片PixelMap数据，所以不适用二分查找scale缩放倍数。这里采用循环递减0.4倍缩放图片，来查找确定最适合的缩放倍数。如果对图片压缩质量要求不高，建议调高每次递减的缩放倍数reduceScale，减少循环，提升scale压缩性能。
          imageScale = imageScale - REDUCE_SCALE;
          await sourcePixelMap.scale(imageScale, imageScale);
          compressedImageData = await AssetUtil.packingJPEGPixelMap(sourcePixelMap, IMAGE_QUALITY);
        } else {
          // imageScale缩放小于等于0时，没有意义，结束压缩。这里不考虑图片缩放倍数小于reduceScale的情况。
          break;
        }
      }
    }
    // 保存图片，返回压缩后的图片信息。
    await AssetUtil.saveAssetData(compressedImageData, filePath);

    let model = new AssetModel();
    model.name = filePath.split('/').pop()!
    model.uri = fileUri.getUriFromPath(filePath);
    model.localPath = filePath;
    model.data = compressedImageData;
    model.dataLength = compressedImageData.byteLength;
    return model
  }

  /**
   * packing二分方式循环压缩
   *
   * @param compressedImageData：图片压缩的ArrayBuffer
   * @param sourcePixelMap：原始待压缩图片的PixelMap
   * @param imageQuality：图片质量参数
   * @param maxCompressedImageByte：压缩目标图像字节长度
   * @returns compressedImageData：返回二分packing压缩后的图片数据
   */
  static async packingCompressedImage(compressedImageData: ArrayBuffer, sourcePixelMap: image.PixelMap, imageQuality: number,
    maxCompressedImageByte: number): Promise<ArrayBuffer> {
    // 图片质量参数范围为0-100，这里以10为最小二分单位创建用于packing二分图片质量参数的数组。
    const packingArray: number[] = [];
    const DICHOTOMY_ACCURACY = 10;
    // 性能知识点: 如果对图片压缩质量要求不高，建议调高最小二分单位dichotomyAccuracy，减少循环，提升packing压缩性能。
    for (let i = 0; i <= 100; i += DICHOTOMY_ACCURACY) {
      packingArray.push(i);
    }
    let left = 0;
    let right = packingArray.length - 1;
    // 二分压缩图片
    while (left <= right) {
      const mid = Math.floor((left + right) / 2);
      imageQuality = packingArray[mid];
      // 根据传入的图片质量参数进行packing压缩，返回压缩后的图片文件流数据。
      compressedImageData = await AssetUtil.packingJPEGPixelMap(sourcePixelMap, imageQuality);
      // 判断查找一个尽可能接近但不超过压缩目标的压缩大小
      if (compressedImageData.byteLength <= maxCompressedImageByte) {
        left = mid + 1;
        if (mid === packingArray.length - 1) {
          break;
        }
        // 获取下一次二分的图片质量参数（mid+1）压缩的图片文件流数据
        compressedImageData = await AssetUtil.packingJPEGPixelMap(sourcePixelMap, packingArray[mid + 1]);
        // 判断用下一次图片质量参数（mid+1）压缩的图片大小是否大于指定图片的压缩目标大小。如果大于，说明当前图片质量参数（mid）压缩出来的图片大小最接近指定图片的压缩目标大小。传入当前图片质量参数mid，得到最终目标图片压缩数据。
        if (compressedImageData.byteLength > maxCompressedImageByte) {
          compressedImageData = await AssetUtil.packingJPEGPixelMap(sourcePixelMap, packingArray[mid]);
          break;
        }
      } else {
        // 目标值不在当前范围的右半部分，将搜索范围的右边界向左移动，以缩小搜索范围并继续在下一次迭代中查找左半部分。
        right = mid - 1;
      }
    }
    return compressedImageData;
  }

}