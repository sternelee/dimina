export interface WebViewLifeCycleListener {
  pageStart(): void;
  pageEnd(): void;
}

export class WebViewLifeCycle {
  private listeners: WebViewLifeCycleListener[] = [];

  registerListener(listener: WebViewLifeCycleListener): void {
    this.listeners.push(listener);
  }

  unregisterListener(listener: WebViewLifeCycleListener): void {
    this.listeners = this.listeners.filter(l => l !== listener);
  }

  notifyPageBegin(): void {
    for (const listener of this.listeners) {
      listener.pageStart();
    }
  }

  notifyPageEnd(): void {
    for (const listener of this.listeners) {
      listener.pageEnd();
    }
  }
}