import { DMPContainerBridgesModule } from '../DMPContainerBridgesModule'

import { DMPBridgeCallback, DMPBridgeCallbackType } from '../DMPTSUtil'
import network from '@system.network';
import { DMPMap } from '../../Utils/DMPMap';

export class DMPContainerBridgesModuleNetwork extends DMPContainerBridgesModule {
  private callbacks: Map<string, DMPBridgeCallback> = new Map();
  private subscribed: boolean = false;

  getExportMethods(): string[] {
    return ['getNetworkType', 'onNetworkStatusChange', 'offNetworkStatusChange'];
  }

  getNetworkType(_: DMPMap, callback: DMPBridgeCallback) {
    let result: DMPMap = new DMPMap()

    network.getType({
      success: (data) => {
        // 网络类型，可能的值有2g，3g，4g，5g，wifi，none等
        result.set('networkType', data.type.toLowerCase())
        this.invokeSuccessCallback(callback, result)
      }
    });
  }

  onNetworkStatusChange(data: DMPMap, callback: DMPBridgeCallback) {
    const callbackId = data.getString('callbackId') ?? data.getString('success');
    if (!callbackId) {
      this.invokeFailureCallback(callback, null, 'onNetworkStatusChange:fail invalid callback');
      return;
    }
    this.callbacks.set(callbackId, callback);
    if (this.subscribed) {
      return;
    }
    this.subscribed = true;
    network.subscribe({
      success: (status) => {
        const networkType = status.type.toLowerCase();
        const result = new DMPMap();
        result.set('isConnected', networkType !== 'none');
        result.set('networkType', networkType);
        this.callbacks.forEach((current: DMPBridgeCallback) => {
          current(result, DMPBridgeCallbackType.Success);
        });
      },
      fail: () => {
        this.callbacks.clear();
        this.subscribed = false;
      }
    });
  }

  offNetworkStatusChange(data: DMPMap, _callback: DMPBridgeCallback) {
    const callbackId = data.getString('callbackId');
    if (callbackId) {
      this.callbacks.delete(callbackId);
    } else {
      this.callbacks.clear();
    }
    if (this.callbacks.size === 0) {
      this.releaseSubscription();
    }
  }

  dispose(): void {
    this.callbacks.clear();
    this.releaseSubscription();
  }

  private releaseSubscription(): void {
    if (!this.subscribed) {
      return;
    }
    network.unsubscribe();
    this.subscribed = false;
  }
}
