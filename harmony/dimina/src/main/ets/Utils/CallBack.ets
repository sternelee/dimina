import { DMPMap } from './DMPMap';

export type OnSuccess = (args?: DMPMap) => void;

export type OnFail = (args?: object | string) => void;

export class CallBack {
  onSuccess?: OnSuccess;
  onFail?: OnFail;
}
