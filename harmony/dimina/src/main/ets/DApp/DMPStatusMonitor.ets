export enum EngineStatus {
  STOP,
  LOADING,
  RUN,
}

export enum RenderStatus {
  domReady,
}


export class StatusMonitor<T> {
  private _currentStatus?: T | undefined = undefined;
  private statusListeners: Set<(status: T, data?: Object) => void> = new Set();

  public get currentStatus(): T | undefined {
    return this._currentStatus;
  }

  setStatus(status: T, data?: Object) {
    this._currentStatus = status;
    for (let listener of this.statusListeners) {
      listener(status, data); // 直接调用函数
    }
  }

  addStatusListener(listener: (status: T) => void) {
    this.statusListeners.add(listener);
  }

  removeStatusListener(listener: (status: T) => void) {
    this.statusListeners.delete(listener);
  }
}