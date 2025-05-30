/**
 * 全局config
 */
import { window } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';

export interface DMPEntryContext {

  getContext: () => common.UIAbilityContext;

  getWindowStage: () => window.WindowStage


}