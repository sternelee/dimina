import { DMPMap } from "../Utils/DMPMap";
import { Request } from "./DRouterRequest";




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

  popToRoot() {
    this.navStack?.popToIndex(-1)
  }
}
