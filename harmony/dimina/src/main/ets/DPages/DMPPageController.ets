export class DMPPageController {
  private _canBack: Boolean = true;

  public set canBack(value: Boolean) {
    this._canBack = value;
  }

  canOnBackPress(): Boolean {
    return this._canBack;
  }
}