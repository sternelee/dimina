import { ComponentContent, promptAction, window } from '@kit.ArkUI'
import { JSON, util } from '@kit.ArkTS'
import { DMPLoadingSettings, loadingDialogGlobalSettings } from './DMPLoadingSettings'
import { common } from '@kit.AbilityKit'

export interface PromptActionOptions<T extends PromptActionBean> {
  builder: WrappedBuilder<[T]>
  params: T,
  options?: DMPLoadingSettings
}

export abstract class PromptActionBean {
  dialogId: string

  constructor(dialogId: string = '') {
    if (dialogId === '') {
      dialogId = util.generateRandomUUID()
    }
    this.dialogId = dialogId
  }
}

interface PromptActionInfo {
  dialogId: string
  componentContent: ComponentContent<object>
}

let promptActionInfos: PromptActionInfo[] = []

function getPromptActionInfoByDialogId(dialogId: string): PromptActionInfo | undefined {
  return promptActionInfos.find(item => dialogId == item.dialogId)
}

export class DMPPromptActionUtils {
  /**
   * 弹出自定义弹窗
   */
  static async openCustomDialog<T extends PromptActionBean>(value: PromptActionOptions<T>): Promise<void> {
    try {
      let context = getContext() as common.UIAbilityContext
      const windowStage = context.windowStage
      const mainWindow = await windowStage.getMainWindow()
      const uiContext = mainWindow.getUIContext()
      const promptAction = uiContext.getPromptAction()
      const componentContent = new ComponentContent(uiContext, value.builder, value.params)

      let hideOnSystemBack = value.options?.hideOnSystemBack ?? loadingDialogGlobalSettings.hideOnSystemBack
      let hideOnTouchOutside = value.options?.hideOnTouchOutside ?? loadingDialogGlobalSettings.hideOnTouchOutside
      let options: promptAction.BaseDialogOptions = {
        alignment: value.options?.alignment ?? loadingDialogGlobalSettings.alignment,
        autoCancel: true,
        maskColor: value.options?.maskColor ?? loadingDialogGlobalSettings.maskColor,
        offset: value.options?.offset ?? loadingDialogGlobalSettings.offset,
        transition: value.options?.transition ?? loadingDialogGlobalSettings.transition,
        showInSubWindow: value.options?.showInSubWindow ?? loadingDialogGlobalSettings.showInSubWindow,
        onWillDismiss: (action: DismissDialogAction) => {
          if (action.reason == DismissReason.PRESS_BACK && hideOnSystemBack) {
            action.dismiss()
          } else if (action.reason == DismissReason.TOUCH_OUTSIDE && hideOnTouchOutside) {
            action.dismiss()
          }
        },
        onWillDisappear: () => {
          const index = promptActionInfos.findIndex(item => item.dialogId == value.params.dialogId)
          if (index >= 0) {
            promptActionInfos.splice(index, 1)
          } else {
            promptActionInfos.shift()
          }
        }
      }

      if (!DMPPromptActionUtils.existsCustomDialog(value.params.dialogId)) {
        promptActionInfos.unshift({
          dialogId: value.params.dialogId,
          componentContent: componentContent
        })
        promptAction.openCustomDialog(componentContent, options)
      }
    } catch (error) {
      console.error('PromptActionUtils', ` openCustomDialog error = ${JSON.stringify(error)}`)
    }
  }

  /**
   * 关闭自定义弹窗
   */
  static async closeCustomDialog(dialogId?: string): Promise<void> {
    try {
      let context = getContext() as common.UIAbilityContext
      const windowStage = context.windowStage
      const mainWindow = await windowStage.getMainWindow()
      const uiContext = mainWindow.getUIContext()
      const promptAction = uiContext.getPromptAction()
      let info: PromptActionInfo | undefined = undefined
      if (dialogId) {
        info = getPromptActionInfoByDialogId(dialogId)
      } else {
        info = promptActionInfos.length > 0 ? promptActionInfos[0] : undefined
      }
      if (info) {
        promptAction.closeCustomDialog(info.componentContent)
      } else {
        console.error('PromptActionUtils', ` closeCustomDialog error = info is undefined`)
      }
    } catch (error) {
      console.error('PromptActionUtils', ` closeCustomDialog error = ${JSON.stringify(error)}`)
    }
  }

  /**
   * 刷新自定义弹窗
   */
  static updateCustomDialog<T extends PromptActionBean>(params: T) {
    let promptActionInfo: PromptActionInfo | undefined = getPromptActionInfoByDialogId(params.dialogId)
    if (promptActionInfo) {
      promptActionInfo.componentContent.update(params)
    }
  }

  /**
   * 是否存在自定义弹窗
   */
  static existsCustomDialog(dialogId: string): boolean {
    let info = getPromptActionInfoByDialogId(dialogId)
    return info != undefined
  }
}