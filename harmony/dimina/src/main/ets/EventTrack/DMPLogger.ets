import { systemDateTime } from '@kit.BasicServicesKit';

export class DMPLogger {
  static commonTag = "[dimina]"
  static isOpenDebugLog = true

  static w(tag: string = '', ...args: string[]) {
    console.warn(`${tag}`, ...args)
  }

  static i(tag: string = '', ...args: string[]) {
    console.info(`${tag}`, ...args)
  }

  static d(tag: string = '', ...args: string[]) {
    console.debug(`${tag}[${systemDateTime.getTime()}]`, ...args)
  }

  static e(tag: string = '', ...args: string[]) {
    console.error(`${tag}`, ...args)
  }
}