import { DMPContextUtils } from "../../Utils/DMPContextUtils";

export const DMPDefaultVirtualFilePrefix: string = 'difile://';

export class DMPVirtualFileConfig {
  private static virtualFilePrefix: string = DMPDefaultVirtualFilePrefix;

  static normalize(prefix: string): string {
    const normalized = prefix.trim().toLowerCase();
    const scheme = normalized.substring(0, normalized.length - 3);
    const isReserved = scheme === 'about' || scheme === 'blob' || scheme === 'content' ||
      scheme === 'data' || scheme === 'dimina' || scheme === 'file' || scheme === 'ftp' ||
      scheme === 'http' || scheme === 'https' || scheme === 'internal' || scheme === 'javascript' ||
      scheme === 'resource' || scheme === 'ws' || scheme === 'wss';
    if (!/^[a-z][a-z0-9+.-]*:\/\/$/.test(normalized) || isReserved) {
      throw new Error('virtualFilePrefix must be a custom URI scheme ending in ://');
    }
    return normalized;
  }

  static configure(prefix: string): void {
    DMPVirtualFileConfig.virtualFilePrefix = DMPVirtualFileConfig.normalize(prefix);
  }

  static getPrefix(): string {
    return DMPVirtualFileConfig.virtualFilePrefix;
  }
}

// vPath example: difile://data/storage/el2/base/haps/entry/files/dm_bundles_v2/dd8a9edfa385c38808/resource
// localPath example: /data/storage/el2/base/haps/entry/files/dm_bundles_v2/dd8a9edfa385c38808/resource
// 涉及到worker线程，移除app相关逻辑，仅处理前缀

export class DMPFileUrlConvertor {
  //鸿蒙原生上传只支持internal://cache 协议
  static uri2UploadImageFilePath(url: string): string {
    const cacheDir = DMPContextUtils.getUIAbilityContext().cacheDir;
    const cacheUri = 'internal://cache'
    const virtualFilePrefix = DMPVirtualFileConfig.getPrefix();
    if (url.startsWith(virtualFilePrefix)) {
      return url.replace(virtualFilePrefix, cacheUri)
    } else if (url.startsWith(cacheDir)) {
      return url.replace(cacheDir, cacheUri)
    }
    return url
  }

  // 将虚拟路径转换为本地路径
  static localPathFromVPath(vPath: string, canvasTempRoot: string = ''): string {
    const canvasFileName = DMPFileUrlConvertor.canvasTempFileName(vPath);
    if (canvasFileName) {
      if (!canvasTempRoot) return vPath;
      return `${canvasTempRoot.replace(/\/+$/, '')}/${canvasFileName}`;
    }
    const virtualFilePrefix = DMPVirtualFileConfig.getPrefix();
    if (vPath.startsWith(virtualFilePrefix)) {
      const localPath = vPath.replace(virtualFilePrefix, "/");
      return localPath;
    }
    return vPath;
  }

  // 将本地路径转换为虚拟路径
  static vPathFromLocalPath(localPath: string): string {
    if (localPath.startsWith('/')) {
      const relativePath = localPath.replace(/^\//, DMPVirtualFileConfig.getPrefix());
      return relativePath;
    }
    return localPath;
  }

  static isDifilePath(path: string): boolean {
    return path.startsWith(DMPVirtualFileConfig.getPrefix());
  }

  static canvasTempRoot(appId: string): string {
    if (appId === '.' || appId === '..' || !/^[A-Za-z0-9._-]+$/.test(appId)) return '';
    return `${DMPContextUtils.getUIAbilityContext().filesDir}/dimina/${appId}/resource/tmp`;
  }

  // 路径归属判定的唯一入口。空 root 一律不放行：canvasTempRoot() 对不合法的 appId 返回空串，
  // 而空串会让 `path.startsWith('/')` 对任何绝对路径都成立，校验失败反而把整条白名单打穿。
  static isUnderAnyRoot(path: string, roots: Array<string>): boolean {
    return roots.some((root: string) => root.length > 0 && (path === root || path.startsWith(`${root}/`)));
  }

  static canvasTempVPath(fileName: string): string {
    return `${DMPVirtualFileConfig.getPrefix()}canvas/${fileName}`;
  }

  static canvasTempFileName(vPath: string): string {
    const canvasTempPrefix = `${DMPVirtualFileConfig.getPrefix()}canvas/`;
    if (!vPath.startsWith(canvasTempPrefix)) return '';
    const fileName = vPath.substring(canvasTempPrefix.length);
    return /^canvas_[0-9a-f-]+\.(png|jpg)$/.test(fileName) ? fileName : '';
  }
}
