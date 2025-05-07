export enum AssetExtType {
  Jpeg = 0,
  Png = 1,
  Webp = 2,
}

export class AssetModel {
  // 示例：IMG_20240429_180041.jpg
  name: string = ''
  // uri，适用于Image的系统控件展示,示例：file://media/Photo/7/IMG_1714381775_006/IMG_20240429_170755.jpg
  uri: string = ''
  // 本地图片地址，示例：/data/storage/el2/base/cache/jzkPic/IMG_20240429_180041.jpg
  localPath: string = ''
  // 图片数据
  data?: ArrayBuffer;
  // 图片数据长度
  dataLength?: number;
}