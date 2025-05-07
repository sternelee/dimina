import { DMPHttpParamsNext } from './DMPHttpParamsNext';
import { DMPLogger } from '../EventTrack/DMPLogger';
import { DMPMap } from '../Utils/DMPMap';
import { http } from '@kit.NetworkKit';
import { request } from './DMPHttp';

export class DMPNetServiceNext {
  params: DMPHttpParamsNext;

  constructor(data: DMPMap, appId: string, appVersion: string) {
    this.params = new DMPHttpParamsNext(data, appId, appVersion);
  }

  request(): Promise<DMPMap> {
    return new Promise<DMPMap>((success, fail) => {
      if (!this.params.canRequest()) {
        let err = new Error('this params is valid')
        fail(err)
        return;
      }
      if (this.params.method.toUpperCase() === 'POST') {
        DMPLogger.d('[network]', 'this.params.url=' + this.params.url)
        request({
          url: this.params.url,
          methodType: http.RequestMethod.POST,
          body: JSON.stringify(this.params.body),
          headers: this.params.headers
        }).then((res: http.HttpResponse) => {
          let code = res.responseCode // http状态码
          let header = new DMPMap(res.header)
          let data: string = res.result as string // 字符串数据
          let result: DMPMap = new DMPMap()
          if (this.params.contentType.includes('json')) {
            result.set('data', JSON.parse(data));
          } else {
            result.set('data', data);
          }
          result.set('statusCode', code);
          result.set('header', header);

          DMPLogger.d('[network]', 'response=' + result.toStr())
          success(result)
        }).catch((error: Error) => {
          fail(error)
        })


      } else if (this.params.method.toUpperCase() === 'GET') {
        request({
          url: this.params.url,
          methodType: http.RequestMethod.GET,
          body: JSON.stringify(this.params.body),
          headers: this.params.headers
        }).then((res: http.HttpResponse) => {
          let code = res.responseCode;
          let header = new DMPMap(res.header);
          let data: string = res.result as string;
          let result: DMPMap = new DMPMap();
          if (this.params.contentType.includes('json')) {
            result.set('data', JSON.parse(data));
          } else {
            result.set('data', data);
          }
          result.set('statusCode', code);
          result.set('header', header);
          DMPLogger.d('[network]', 'response=' + result.toStr())
          success(result);
        }).catch((error: Error) => {
          fail(error)
        })
      }
    })
  }
}