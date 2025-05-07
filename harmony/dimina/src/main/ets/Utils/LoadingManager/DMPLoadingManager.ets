import { DMPLoadingDialogSettings, DMPLoadingSettings, loadingDialogGlobalSettings } from './DMPLoadingSettings'
import { DMPLoadingActionOptions, DMPLoadingDialogBuilder, DMPLoadingState } from './DMPLoadingViews'
import { DMPPromptActionUtils } from './DMPPromptActionUtils'

export class DMPLoadingManager {
  /**
   * 设置全局默认参数
   */
  static setGlobalSettings(configs: (settings: DMPLoadingDialogSettings) => void): void {
    configs(loadingDialogGlobalSettings)
  }

  /**
   * 显示 loading hud
   * @param value 可不传
   */
  static async showLoading(value: string | DMPLoadingSettings = ''): Promise<void> {
    await DMPLoadingManager.showDialog(new DMPLoadingActionOptions(DMPLoadingState.LOADING, value))
  }

  /**
   * 显示 success hud
   * @param value 可不传
   */
  static async showSuccess(value: string | DMPLoadingSettings = ''): Promise<void> {
    await DMPLoadingManager.showDialog(new DMPLoadingActionOptions(DMPLoadingState.SUCCESS, value))

    DMPLoadingManager.hideDialogDelay(DMPLoadingState.SUCCESS, value)
  }

  static  async showIconProgress(value: string | DMPLoadingSettings = ''): Promise<void> {
    await DMPLoadingManager.showDialog(new DMPLoadingActionOptions(DMPLoadingState.ICONPROGRESS, value))
  }

  /**
   * 显示 failure hud
   * @param value 可不传
   */
  static async showFailure(value: string | DMPLoadingSettings = ''): Promise<void> {
    await DMPLoadingManager.showDialog(new DMPLoadingActionOptions(DMPLoadingState.ERROR, value))

    DMPLoadingManager.hideDialogDelay(DMPLoadingState.ERROR, value)
  }

  /**
   * 显示 info hud
   * @param value 可不传
   */
  static async showInfo(value: string | DMPLoadingSettings = ''): Promise<void> {
    await DMPLoadingManager.showDialog(new DMPLoadingActionOptions(DMPLoadingState.INFO, value))

    DMPLoadingManager.hideDialogDelay(DMPLoadingState.INFO, value)
  }

  /**
   * 显示 warn hud
   * @param value
   */
  static async showWarn(value: string | DMPLoadingSettings = ''): Promise<void> {
    await DMPLoadingManager.showDialog(new DMPLoadingActionOptions(DMPLoadingState.WARN, value))

    DMPLoadingManager.hideDialogDelay(DMPLoadingState.WARN, value)
  }

  /**
   * 显示 toast hud
   * @param value
   */
  static async showToast(value: string | DMPLoadingSettings = ''): Promise<void> {
    await DMPLoadingManager.showDialog(new DMPLoadingActionOptions(DMPLoadingState.TOAST, value))

    DMPLoadingManager.hideDialogDelay(DMPLoadingState.TOAST, value)
  }

  /**
   * 显示 progress hud
   * @param value 可不传
   * @param progress 取值 0 ~ 100
   */
  static async showProgress(value: string | DMPLoadingSettings = '', progress: number = 0): Promise<void> {
    let options = new DMPLoadingActionOptions(DMPLoadingState.PROGRESS, value, progress)
    if (DMPPromptActionUtils.existsCustomDialog(DMPLoadingState.PROGRESS)) {
      DMPLoadingManager.updateDialog(options)
    } else {
      await DMPLoadingManager.showDialog(options)
    }
  }

  /**
   * 隐藏 hud
   */
  static async hide(dialogId?: string): Promise<void> {
    await DMPPromptActionUtils.closeCustomDialog(dialogId)
  }

  /////////////////////////////////  privates  /////////////////////////////////
  static async showDialog(options: DMPLoadingActionOptions): Promise<void> {
    let settings: DMPLoadingSettings = typeof options.value == 'string' ? {} : options.value
    if (options.dialogId == DMPLoadingState.PROGRESS) {
      settings.transition = TransitionEffect.IDENTITY
    } else {
      await DMPLoadingManager.hide()
    }
    await DMPPromptActionUtils.openCustomDialog<DMPLoadingActionOptions>({
      builder: wrapBuilder(DMPLoadingDialogBuilder),
      params: options,
      options: settings
    })
  }

  static  updateDialog(options: DMPLoadingActionOptions): void {
    DMPPromptActionUtils.updateCustomDialog<DMPLoadingActionOptions>(options)
  }

  static  hideDialogDelay(dialogId?: string, value: string | DMPLoadingSettings = ''): void {
    let hideDelay: number
    if (typeof value == 'string') {
      hideDelay = loadingDialogGlobalSettings.hideDelay
    } else {
      hideDelay = value.hideDelay ?? loadingDialogGlobalSettings.hideDelay
    }
    setTimeout(() => {
      DMPLoadingManager.hide(dialogId)
    }, hideDelay)
  }
}