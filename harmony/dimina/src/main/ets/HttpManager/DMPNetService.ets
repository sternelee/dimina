
import { http } from '@kit.NetworkKit';
import { DMPMap } from '../Utils/DMPMap';
import { request } from './DMPHttp';
import { DMPHttpParams } from './DMPHttpParams';


export class DMPNetService {
  params: DMPHttpParams;
  appIndex: number;

  constructor(appIndex: number, data?: DMPMap, params?: DMPHttpParams) {
    this.appIndex = appIndex;
    if (params) {
      this.params = params;
    } else {
      this.params = new DMPHttpParams(appIndex,data);
    }
  }

  request(): Promise<DMPMap> {
    return new Promise<DMPMap>((success, fail) => {
      if (!this.params.canRequest()) {
        let err = new Error('this params is valid')
        fail(err)
        return;
      }

      if (this.params.method.toLowerCase() === 'post') {
        request({
          url: this.params.url,
          methodType: http.RequestMethod.POST,
          body:JSON.stringify(this.params.data),
          headers:this.params.header
        }).then((res:http.HttpResponse)=>{
              let result: DMPMap = new DMPMap()
              if (this.params.contentType.includes('json')) {
                result = new DMPMap()
              }
              success(result)
        }).catch((error: Error)=>{
              fail(error)
        })
      } else if (this.params.method.toLowerCase() === 'get') {
        request({
          url: this.params.url,
          methodType: http.RequestMethod.GET,
          body:JSON.stringify(this.params.data),
          headers:this.params.header
        }).then((res:http.HttpResponse)=>{
          let data: string = res.result as string // 字符串数据
          let result: DMPMap = new DMPMap()
          if (this.params.contentType.includes('json')) {
            result = new DMPMap(JSON.parse(data))
          } else {
            result.set('data', data);
          }
          success(result)
        }).catch((error: Error)=>{
          fail(error)
        })
      }
    })
  }
}