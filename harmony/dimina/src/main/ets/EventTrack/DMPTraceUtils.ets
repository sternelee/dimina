import { systemDateTime } from '@kit.BasicServicesKit'
import { DMPLogger } from './DMPLogger'

/**
 * 简单耗时统计工具
 */
export class TraceUtils {
  private static timers: Map<string, number> = new Map()

  static start(label: string) {
    TraceUtils.timers.set(label, systemDateTime.getTime())
  }

  static end(label: string,tag:string) {
    const startTime = TraceUtils.timers.get(label)
    if (startTime !== undefined) {
      let current = systemDateTime.getTime();
      const cost = current - startTime
      DMPLogger.e(`TraceUtils ${label}:${tag} launch time=${cost}`)
      TraceUtils.timers.set(label, current)
    } else {
      DMPLogger.e(`TraceUtils ${label}:${tag} has not been started`)
    }
  }
}