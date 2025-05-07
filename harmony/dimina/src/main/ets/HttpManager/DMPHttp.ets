import { http } from "@kit.NetworkKit"
import { DMPMap } from "../Utils/DMPMap";

export async function request(option: DMPRequestOption): Promise<http.HttpResponse> {
  let options: http.HttpRequestOptions = {
    method: option.methodType,
    extraData: option.body, //body string
    expectDataType: undefined,
    usingCache: false,
    header: option.headers?.toJSON(),
    readTimeout: option.readTimeOut,
    connectTimeout: option.connectTimeout,
    usingProxy: false,
    caPath: undefined
  }
  return await http.createHttp().request(option.url, options)

}

export interface DMPRequestOption {
  headers?: DMPMap;
  body?: string;
  url: string;
  methodType: http.RequestMethod
  readTimeOut?: number
  connectTimeout?: number
}