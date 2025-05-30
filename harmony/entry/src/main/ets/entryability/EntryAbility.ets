import { AbilityConstant, common, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { WindowManager } from '@kit.SpeechKit';
import { DMPEntryContext } from '@didi-dimina/dimina/src/main/ets/DApp/config/DMPEntryContext';
import { DMPApp } from '@didi-dimina/dimina/src/main/ets/DApp/DMPApp';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    let windowClass: window.Window = windowStage.getMainWindowSync()

    windowStage.loadContent('pages/Index', (err, data) => {
      if (err.code) {
        hilog.error(0x0000, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }

      // 获取应用主窗口
      windowStage.getMainWindow().then(async (windowClass) => {
        windowClass.setWindowLayoutFullScreen(true)
        AppStorage.setOrCreate("mainWindow", windowClass);
        let type = window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR; // 以导航条避让为例
        let avoidArea = windowClass.getWindowAvoidArea(type);
        let bottomRectHeight = avoidArea.bottomRect.height; // 获取到导航条区域的高度
        let topRectHeight = avoidArea.topRect.height; // 获取到导航条区域的高度
        AppStorage.setOrCreate('bottomRectHeight', bottomRectHeight);
        let topAvoidArea = await this.getTopWindowAvoidArea(this.context)
        AppStorage.setOrCreate('topRectHeight', topAvoidArea?.topRect.height);

      })

      // 沉浸式设置
      windowClass?.setWindowBackgroundColor('#ffffff');
    });


    let dmpConfig: DMPEntryContext = {
      getContext: (): common.UIAbilityContext => {
        return this.context;
      },
      getWindowStage: (): window.WindowStage => {
        return windowStage;
      }
    };
    DMPApp.init(dmpConfig);
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onBackground');
  }

   async getTopWindowAvoidArea(context: common.UIAbilityContext): Promise<window.AvoidArea | null> {
    try {
      const mainWindow = await window.getLastWindow(context);
      const avoidAreaType = window.AvoidAreaType.TYPE_SYSTEM; // 系统默认区域，包括状态栏，导航栏
      const avoidArea = mainWindow.getWindowAvoidArea(avoidAreaType);
      const height = avoidArea.topRect.height;
      return avoidArea;
    } catch (e) {
      console.log('getWindowAvoidArea fail');
      return null
    }
  }
}
