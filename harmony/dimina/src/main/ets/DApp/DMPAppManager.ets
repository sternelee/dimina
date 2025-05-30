
import { DMPAppConfig } from './config/DMPAppConfig'

import { DMPApp } from './DMPApp'
import { DMPLogger } from '../EventTrack/DMPLogger'
import { Tags } from '../EventTrack/Tags'

export class DMPAppManager {
  private static instance: DMPAppManager
  appPools = new Map<number, DMPApp>();
  private appIndex = 0;

  public static sharedInstance(): DMPAppManager {
    if (!DMPAppManager.instance) {
      DMPAppManager.instance = new DMPAppManager()
    }
    return DMPAppManager.instance
  }


  getApp(appIndex: number): DMPApp | undefined {
    return this.appPools.get(appIndex);
  }

  newAppWithConfig(appConfig: DMPAppConfig): DMPApp {
    this.appIndex++;
    let newApp = new DMPApp(appConfig, this.appIndex)
    DMPAppManager.sharedInstance().appPools.set(this.appIndex, newApp)
    return newApp
  }

  appWithConfig(appConfig: DMPAppConfig): DMPApp {
    DMPLogger.d(Tags.LAUNCH, "appWithConfig config=" + JSON.stringify(appConfig))
    let exitApp: DMPApp | null = this.existApp(appConfig.appId)
    if (exitApp != null) {
      DMPLogger.i(Tags.LAUNCH, "appWithConfig return exist DMPApp")
      return exitApp
    }
    DMPLogger.i(Tags.LAUNCH, "appWithConfig create DMPApp")
    this.appIndex++;
    let newApp = new DMPApp(appConfig, this.appIndex)
    DMPAppManager.sharedInstance().appPools.set(this.appIndex, newApp)
    return newApp
  }

  existApp(appId: string): DMPApp | null {
    let result: DMPApp | null = null
    this.appPools.forEach((app) => {
      if (app.appConfig.appId === appId) {
        result = app
      }
    })
    return result
  }

  exitApp(appId: string) {
    let index: number | null = null
    this.appPools.forEach((app, key) => {
      if (app.appConfig.appId === appId) {
        index = key;
      }
    })
    if (index) {
      this.appPools.delete(index)
    }
  }
}