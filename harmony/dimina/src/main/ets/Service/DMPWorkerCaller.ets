import { DMPChannelProxyNext } from './DMPChannelProxyNext';
import { DMPMap } from '../Utils/DMPMap';

// 这个类会被 Worker 强引用，越简单越好，依赖越少越好
export class DMPWorkerCaller {
  public toContainer(type: string, body: object,
    target: string, appIndex: number): DMPMap | number | string | boolean | object {
    // DMPLogger.d(Tags.JS_ENGINE, `fromService 2 ${type} ${JSON.stringify(body)} ${target}`);
    const result = DMPChannelProxyNext.messageHandlerWithAppIndex(type, DMPMap.createFromObject(body), target, appIndex);

    // DMPMap 这个类型不要于线程之间传递，会导致意料之外的错误
    if (result instanceof DMPMap) {
      // DMPLogger.d(Tags.JS_ENGINE, `caller 1 ${result.toStr()}`);
      return result.toJSON();
    } else if (typeof result === "object" && result !== null) {
      // DMPLogger.d(Tags.JS_ENGINE, `caller 2 ${JSON.stringify(result)}`);
    } else {
      // DMPLogger.d(Tags.JS_ENGINE, `caller 3 ${result}`);
    }
    return result;
  }

  public toRender(webViewId: number, msg: string, appIndex: number) {
    const result = DMPChannelProxyNext.ServiceToRenderWithAppIndex(msg, webViewId, appIndex);
    return result;
  }
}
