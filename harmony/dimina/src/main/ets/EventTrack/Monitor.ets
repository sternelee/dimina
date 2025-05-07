
import { Tags } from './Tags';
import { DMPLogger } from './DMPLogger';

export enum DMPMonitorExceptionKey {
  JSEngineException = "JSEngineException",
  WebviewException = "WebviewException",
  BridgeException = "BridgeException",
  JSException = "JSException",
  WindowAPIException = "WindowAPIexception",
  MsgException = "MsgException"
}

export  enum DiminaPageString { PAGE_DOM_READY = 'page_domReady', PAGE_FIRST_DOM_READY = 'page_first_domReady', PAGE_HOME_RENDER_FINISH = 'home_page_renderFinish', PAGE_ACTIVITY_ON_START = 'activity_onStart', PAGE_ACTIVITY_ON_STOP = 'activity_onStop', PAGE_ACTIVITY_ON_DESTROY = 'activity_onDestroy',
PAGE_ON_CREATE = "page_onCreate",  PAGE_ON_SHOW = "page_onShow",  PAGE_ON_HIDE = "page_onHide",  PAGE_ON_DESTROY = "page_onDestroy",
PAGE_RELOAD_WEB_VIEW = 'page_reLoadWebView',PAGE_RELEASE_WEB_VIEW = 'page_releaseWebView',PAGE_PRELOAD_WEB_VIEW = 'page_preloadWebView',
PAGE_INVOKE_PARAMS_TO_WIN_DONE = 'page_invokeParamsToWinDone',
LAUNCH_DIMINA = "launch_dimina",LAUNCH_DIMINA_OPEN = "launch_dimina_open", LAUNCH_LOADED_APP_CONFIG_JSON = "launch_loaded_app_config_json",
LAUNCH_LOADED_DM_SERVICE_JS_START = "launch_loaded_dm_service_js_start",LAUNCH_LOADED_DM_SERVICE_JS_END = "launch_loaded_dm_service_js_end",
LAUNCH_LOADED_APP_SERVICE_JS_START = "launch_loaded_app_service_js_start",LAUNCH_LOADED_APP_SERVICE_JS_END = "launch_loaded_app_service_js_end",
LAUNCH_INVOKE_SERVICE_READY = "launch_invokeServiceReady",LAUNCH_NATIVE_JS_READY = "launch_nativeJsReady",LAUNCH_INVOKE_BUSINESS_READY = "launch_invokeBusinessReady",
LAUNCH_LAUNCH_PAGE = "launch_launchPage",
NAVIGATE_SHOW_STACK = "navigate_showStack",NAVIGATE_HIDE_STACK = "navigate_hideStack",NAVIGATE_REMOVE_STACK = "navigate_removeStack",
NAVIGATE_PUSH_PAGE = "navigate_pushPage",NAVIGATE_LAUNCH = "navigate_launch",NAVIGATE_RELAUNCH = "navigate_relaunch",
NAVIGATE_REDIRECT_TO = "navigate_redirectTo",NAVIGATE_NAVIGATE_TO = "navigate_navigateTo",NAVIGATE_NAVIGATE_BACK = "navigate_navigateBack",
NAVIGATE_GET_CURRENT_PAGES = "navigate_getCurrentPages",NAVIGATE_CLOSE_DIMINA = "navigate_closeDimina",
NAVIGATE_ON_CLOSE_MINI_PROGRAM = "navigate_onCloseMiniProgram",NAVIGATE_NAVIGATE_BACK_NATIVE = "navigate_navigateBackNative",

PACKAGE_LOAD_JS_FILE_TO_DATA_THREAD_START = "package_loadJSFileToDataThread_start",
PACKAGE_LOAD_JS_FILE_TO_DATA_THREAD_SUCCESS = 'package_loadJSFileToDataThread_success', PACKAGE_LOAD_JS_FILE_TO_DATA_THREAD_FAILED = 'package_loadJSFileToDataThread_failed',
PACKAGE_PRELOAD_SUB_PACKAGE_START = 'package_preloadSubPackage_start',
PACKAGE_PRELOAD_SUB_PACKAGE_FAILED = 'package_preloadSubPackage_failed', PACKAGE_PRELOAD_SUB_PACKAGE_SUCCESS = 'package_preloadSubPackage_success',
PACKAGE_LOAD_SUB_PACKAGE_START = 'package_loadSubPackage_start',
PACKAGE_LOAD_SUB_PACKAGE_FAILED = 'package_loadSubPackage_failed', PACKAGE_LOAD_SUB_PACKAGE_SUCCESS = 'package_loadSubPackage_success',


}


export function monitorEvent(event: string, params: Map<string, string>) {

}

export function monitorException(type: DMPMonitorExceptionKey, appId: string, error: Error, info?: Map<string, string>) {

}

export function monitorCoreEvent(event: DiminaPageString, info: string){
  DMPLogger.i(Tags.DIMINA_CORE,   event +' ' + info);
}

