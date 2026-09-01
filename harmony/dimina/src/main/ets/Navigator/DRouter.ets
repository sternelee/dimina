import { DMPMap } from "../Utils/DMPMap";
import { Request } from "./DRouterRequest";

/**
 * Converts an owned route-entry count into the index that must remain at the
 * top of NavPathStack. A target of -1 means returning to Navigation's home
 * content and removing every NavDestination.
 */
export class DMPNavPathPopPlan {
  static targetIndex(stackSize: number, popCount: number): number | undefined {
    if (stackSize <= 0 || popCount <= 0) {
      return undefined
    }
    const actualPopCount = Math.min(stackSize, popCount)
    return stackSize - actualPopCount - 1
  }
}

export class DRouter {
  private navStack?: NavPathStack;
  private static instance?: DRouter;

  private constructor() {
  }

  init(navStack: NavPathStack) {
    this.navStack = navStack;
  }

  static getInstance(): DRouter {
    if (!DRouter.instance) {
      DRouter.instance = new DRouter();
    }
    return DRouter.instance;
  }

  public build(routeName: string): Request {
    return new Request(routeName);
  }

  replace(routeName: string, extras: DMPMap) {
    this.navStack?.replacePathByName(routeName, extras)
  }

  push(routeName: string, extras: DMPMap) {
    this.navStack?.pushPathByName(routeName, extras)
  }

  pop(animated: boolean = true) {
    this.navStack?.pop(animated)
  }

  /**
   * Pops a contiguous group of Dimina-owned destinations as one Navigation
   * operation. This gives closeMiniProgram one visible transition instead of
   * scheduling an animation for every page in the mini-program stack.
   */
  popEntries(count: number, animated: boolean = true) {
    const navStack = this.navStack
    if (!navStack) {
      return
    }
    const targetIndex = DMPNavPathPopPlan.targetIndex(navStack.size(), count)
    if (targetIndex === undefined) {
      return
    }
    navStack.popToIndex(targetIndex, animated)
  }

  popToRoot() {
    this.navStack?.popToIndex(-1)
  }
}
