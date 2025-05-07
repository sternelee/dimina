import { List } from '@kit.ArkTS'
import { DMPMap } from '../../Utils/DMPMap'
import { promptAction } from '@kit.ArkUI'


export enum DMPShareSDKChannel {
  None = 0,
  WeChat            = 1, // 微信好友分享
  WeChatFriend      = 2, // 微信朋友圈分享
  AliSceneSession   = 3, // 支付宝好友分享
  AliSceneTimeLine  = 4,//< 支付宝生活圈分享
  QQ                = 5, ///< QQ好友分享
  QQZone            = 6, ///< QQ空间分享,
  Message           = 7, ///< 短信分享
  WeiBo             = 8, ///< 新浪微博分享        ！！！已不再支持
  Facebook          = 9, ///< Facebook 分享
  FBMessenger       = 10,///< Facebook messenger 分享
  WhatsApp          = 11,///< WhatsApp 分享
  Line              = 12,///< Line 分享
  Twitter           = 13,///< Twitter分享
  EMail             = 14,///< e-mail 分享
  DingTalk          = 15,///< 钉钉分享
  CopyLink          = 16,///< 复制链接
  SavePicture       = 17,///< 保存图片
  SystemPanel       = 18,///< 打开系统面板
}


export enum DMPShareCallbackResultType {
  Successed = 0,
  Faild = 1,
  Cancel = 2
}


export class DMPShareComponent {
  static DMPShareChannelsDict: Map<string, Object> = new Map()
  shareDatas: List<Object> = new List()
  url: string = ''

  static sharedComponent() {
    return new DMPShareComponent()
  }

  shareCallback: (result: DMPMap) => void = (result: DMPMap) => {

  }

  shareData(shareData: DMPMap, toChannel: number) {
    promptAction.showToast({
      message: '暂不支持微信分享',
      alignment: Alignment.Center
    })
  }

  popShare() {
    promptAction.showToast({
      message: '暂不支持微信分享',
      alignment: Alignment.Center
    })
  }

  hideShare() {

  }
}