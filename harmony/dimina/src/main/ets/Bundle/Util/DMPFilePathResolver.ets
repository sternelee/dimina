import fs from '@ohos.file.fs';
import { DMPContextUtils } from '../../Utils/DMPContextUtils';
import { DMPFileUrlConvertor } from './DMPFileUrlConvertor';

const VIRTUAL_PREFIX = 'difile://';
const USER_PREFIX = 'usr';
const TEMP_PREFIX = 'tmp';

/**
 * Resolve mini-program file paths without allowing one app to escape into
 * another app's files, shared cache entries, or host-owned paths.
 */
export class DMPFilePathResolver {
  static userRoot(appId: string): string {
    const root = `${DMPContextUtils.getUIAbilityContext().filesDir}/dimina-file-system/${appId}/${USER_PREFIX}`;
    this.ensureDirectory(root);
    return this.normalizeAbsolutePath(root);
  }

  static tempRoot(appId: string): string {
    const root = `${DMPContextUtils.getUIAbilityContext().cacheDir}/dimina-file-system/${appId}/${TEMP_PREFIX}`;
    this.ensureDirectory(root);
    return this.normalizeAbsolutePath(root);
  }

  static resolve(rawPath: string, appId: string, packageRoot?: string): string {
    if (!rawPath) {
      throw new Error('missing file path');
    }
    const userRoot = this.userRoot(appId);
    const tempRoot = this.tempRoot(appId);
    let candidate = rawPath;

    if (rawPath.startsWith(`${VIRTUAL_PREFIX}${USER_PREFIX}`)) {
      const relative = rawPath.substring(`${VIRTUAL_PREFIX}${USER_PREFIX}`.length).replace(/^\/+/, '');
      candidate = `${userRoot}/${relative}`;
    } else if (rawPath.startsWith(`${VIRTUAL_PREFIX}${TEMP_PREFIX}`)) {
      const relative = rawPath.substring(`${VIRTUAL_PREFIX}${TEMP_PREFIX}`.length).replace(/^\/+/, '');
      candidate = `${tempRoot}/${relative}`;
    } else if (rawPath.startsWith(VIRTUAL_PREFIX)) {
      candidate = DMPFileUrlConvertor.localPathFromVPath(rawPath);
    } else if (!rawPath.startsWith('/')) {
      if (!packageRoot) {
        throw new Error(`permission denied, open ${rawPath}`);
      }
      return this.resolvePackagePath(rawPath, packageRoot);
    }

    const path = this.normalizeAbsolutePath(candidate);
    const normalizedPackageRoot = packageRoot ? this.normalizeAbsolutePath(packageRoot) : '';
    const allowedRoot = [userRoot, tempRoot, normalizedPackageRoot]
      .find((root: string) => root.length > 0 && this.isWithin(path, root));
    if (!allowedRoot) {
      throw new Error(`permission denied, open ${rawPath}`);
    }
    this.assertNoSymbolicLinks(path, allowedRoot);
    return path;
  }

  static ensureDirectory(path: string): void {
    if (!fs.accessSync(path)) {
      fs.mkdirSync(path, true);
    }
  }

  private static resolvePackagePath(rawPath: string, packageRoot: string): string {
    const relative = this.normalizeRelativePath(rawPath);
    const root = this.normalizeAbsolutePath(packageRoot);
    const direct = this.normalizeAbsolutePath(`${root}/${relative}`);
    const main = this.normalizeAbsolutePath(`${root}/main/${relative}`);
    const candidate = fs.accessSync(direct) ? direct : main;
    if (!this.isWithin(candidate, root)) {
      throw new Error(`permission denied, open ${rawPath}`);
    }
    this.assertNoSymbolicLinks(candidate, root);
    return candidate;
  }

  private static normalizeRelativePath(path: string): string {
    if (path.includes('\\') || path.includes('\0')) {
      throw new Error('invalid file path');
    }
    const segments = path.split('/').filter((segment: string) => segment.length > 0 && segment !== '.');
    if (segments.length === 0 || segments.some((segment: string) => segment === '..')) {
      throw new Error('invalid file path');
    }
    return segments.join('/');
  }

  private static normalizeAbsolutePath(path: string): string {
    if (!path.startsWith('/') || path.includes('\\') || path.includes('\0')) {
      throw new Error('invalid file path');
    }
    const normalized = new Array<string>();
    path.split('/').forEach((segment: string) => {
      if (!segment || segment === '.') {
        return;
      }
      if (segment === '..') {
        if (normalized.length === 0) {
          throw new Error('invalid file path');
        }
        normalized.pop();
        return;
      }
      normalized.push(segment);
    });
    return `/${normalized.join('/')}`;
  }

  private static isWithin(path: string, root: string): boolean {
    return path === root || path.startsWith(`${root}/`);
  }

  private static assertNoSymbolicLinks(path: string, root: string): void {
    const relative = path.substring(root.length).replace(/^\/+/, '');
    let current = root;
    if (fs.accessSync(current) && fs.lstatSync(current).isSymbolicLink()) {
      throw new Error('symbolic links are not allowed');
    }
    relative.split('/').filter((segment: string) => segment.length > 0).forEach((segment: string) => {
      current = `${current}/${segment}`;
      if (fs.accessSync(current) && fs.lstatSync(current).isSymbolicLink()) {
        throw new Error('symbolic links are not allowed');
      }
    });
  }
}
