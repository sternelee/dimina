export class ActionSheetController {
  params?: ActionSheetParams;
  private onShow?: (data: ActionSheetParams) => void;
  private _onSelectListener?: ((index: number) => void) | undefined;

  public get onSelectListener(): ((index: number) => void) | undefined {
    return this._onSelectListener;
  }

  constructor() {
  }

  // 设置显示时的回调函数
  setOnShowCallback(callback: (data: ActionSheetParams) => void) {
    this.onShow = callback;
  }

  setOnSelectListener(onSelectListener: (index: number) => void) {
    this._onSelectListener = onSelectListener;
  }

  open() {
    if (this.onShow && this.params) {
      this.onShow(this.params);
    }
  }
}

export interface ActionSheetParams {
  title?: string
  color?: string
  items?: Array<string>
}