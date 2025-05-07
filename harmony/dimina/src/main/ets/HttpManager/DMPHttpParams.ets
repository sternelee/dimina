


import Url from '@ohos.url'
import { DMPAppManager } from '../DApp/DMPAppManager';
import { DMPApp } from '../DApp/DMPApp';
import { DMPMap } from '../Utils/DMPMap';

export class DMPHttpParams {
  // canRequest: boolean = false;
  appIndex: number
  url: string = '';
  header: DMPMap | undefined;
  method: string = '';
  private bodyData: DMPMap | undefined;
  dataType: string = '';
  contentType: string = ''
  taskId: string = '';
  private paramData: DMPMap | null;
  data: Record<string, string> | null

  constructor(appIndex: number, data?: DMPMap) {
    this.appIndex = appIndex
    if (data) {
      this.taskId = data.get('taskId') ?? '';
      this.paramData = data.get('options') ?? null
      this.data = null
      if (this.paramData) {
        this.data = this.paramData.get('data') ?? null
      }
      this.configParamData()
    } else {
      this.paramData = null;
      this.data = null;
    }
  }

  canRequest(): boolean {
    if (this.url.length > 0) {
      return true;
    }
    return false
  }

  private configParamData() {
    if (this.paramData) {
      this.url = this.paramData.get('url')
      // this.header = this.paramData['header']?? undefined
      this.method = this.paramData.get('method') ?? 'GET'
      this.dataType = this.paramData.get('dataType') ?? 'json'
      this.bodyData = this.paramData.get('data') ?? new Map()
      this.build();
    }

  }

  public build() {
    this.method = this.method.toUpperCase()
    this.configUrlParam();
    this.configHeaders();
  }

  private configUrlParam() {
    if (!this.data || this.method !== 'GET') {
      return;
    }
    const urlParams = new Url.URLParams(this.data);
    const url = this.url;
    let newUrl = ''
    if (url.includes('?')) {
      newUrl = url + '&' + urlParams.toString()
    } else {
      newUrl = url + '?' + urlParams.toString()
    }
    this.url = newUrl;
  }

  private configHeaders() {
    let headerParam: Map<string, string> = new Map();
    if (this.paramData) {
      headerParam = this.paramData.get('header')
    }
    headerParam['test'] = 'aaa';
    // 补充userAgent 和 referer 和Content-Type
    this.addCommonHeaderParams(headerParam);
    const headers = new DMPMap()
    for (let key of Object.keys(headerParam)) {
      let value: string = headerParam[key];
      headers.set(key,value);
    }
    this.header = headers;
  }

  private addCommonHeaderParams(param: Map<string, string>) {
    // 补充userAgent 和 referer 和Content-Type
    if (!param) {
      param = new Map();
    }
    let hasKey = false
    for (let key of Object.keys(param)) {
      if (key.toLowerCase().includes('user-agent')) {
        hasKey = true;
        let name: string = key!
        let value: string = param[name]
        param[key] = value + ' ' + 'HarmonyOS'
      }
    }
    if (!hasKey) {
      // 我也不知道具体是什么
      // param['User-Agent'] = `Mozilla/5.0 (HUAWEI; CPU Harmony OS ) WebKit(KHTML, like Gecko) Mobile /dimina miniProgram`
    }
    // if (!param.has('referer')) {
    if (!param['referer']) {
      let app: DMPApp | undefined = DMPAppManager.sharedInstance().getApp(this.appIndex);
      if (app) {
        let appid = app.appConfig.appId;
        let appVersion = app.appVersion;
        param['referer'] = `https://servicedimina.com/${appid}/${appVersion}/page-frame.html`
      }
    }

    let contentType: string = param['Content-Type'] ?? param['content-type']
    if (!contentType || contentType.length === 0) {
      contentType = "application/json"
    }
    this.contentType = contentType
  }
}