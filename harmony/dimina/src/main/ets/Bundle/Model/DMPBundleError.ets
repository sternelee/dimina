export class ErrorCode {
  //有底包安装失败
  static INSTALL_REMOTE_JSAPP_FAILED = -10000
  //无底包安装失败，无法启动
  static INSTALL_REMOTE_JSAPP_ERROR = -10001
  //安装远程jssdk 失败
  static INSTALL_REMOTE_JSSDK_FAILED = -10002
  //远程包不完整，无法启动
  static INSTALL_REMOTE_ERROR = -10003
  //加载远程包失败
  static LOAD_REMOTE_FAILED = -10004
  //预加载错误
  static LOAD_PREV_REMOTE_BUNDLE_FAILED = -10005
  //加载本地包失败
  static LOAD_LOCAL_BUNDLE_FAILED = -10010
  //预加载缓存配置失败
  static LOAD_CACHE_CONFIG_FAILED = -10011
  //启动错误
  static LAUNCH_FAILED = -10012

}