import diminaNative from 'libdimina.so'


export class DMPJSEngine {
  private isRun = false;
  private appIndex: number = -1;

  constructor() {
  }

  evalJS(script: string) {
    if (this.isRun) {
      diminaNative.dispatchJsTask(this.appIndex, script)
    } else {
      console.log('js engine is destroy')
    }
  }

  evalJSAb(ab: ArrayBuffer) {
    if (this.isRun) {
      diminaNative.dispatchJsTaskAb(this.appIndex, ab)
    } else {
      console.log('js engine is destroy')
    }
  }

  evalJSPath(path: string) {
    if (this.isRun) {
      diminaNative.dispatchJsTaskPath(this.appIndex, path)
    } else {
      console.log('js engine is destroy')
    }
  }

  destroy() {
    this.isRun = false
    diminaNative.destroyJsEngine(this.appIndex)
  }

  initWithWorker(appIndex: number,
    serviceToContainer: (t: number, id: number, d: string, a: ArrayBuffer) => number | string | boolean | object,
    isDebugMode: boolean) {
    this.appIndex = appIndex;

    this.isRun = true;

    diminaNative.StartJsEngine(this.appIndex, (t: number, id: number, data: string, ab: ArrayBuffer) => {
      // DMPLogger.d(Tags.JS_ENGINE, `StartJsEngine, ${t}, ${id}, ${data}`)
      return serviceToContainer(t, id, data, ab);
    }, isDebugMode)
  }
}

