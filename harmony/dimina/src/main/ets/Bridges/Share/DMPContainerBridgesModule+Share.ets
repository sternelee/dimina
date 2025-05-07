import { DMPMap } from '../../Utils/DMPMap'
import { DMPContainerBridgesModule } from '../DMPContainerBridgesModule'
import { DMPBridgeCallback } from '../DMPTSUtil'
import { DMPShareComponent, DMPShareSDKChannel } from './DMPShareComponent'

export class DMPContainerBridgesModuleShare extends DMPContainerBridgesModule {
  getExportMethods(): string[] {
    return ['customShare',
      'showShareEntrance',
      'hideShareEntrance',
      'shareWeixinAppmsg',
      'shareWeixinTimeline',
      'shareQzone',
      'shareQqAppmsg',
      'shareAlipayFriend',
      'shareAlipayLife',
      'shareMessage',
      'shareSinaWeibo',
      'shareFacebook',
      'shareTwitter',
      'shareWhatsApp',
      'shareEMail',
      'shareSavePicture'
    ];
  }

  customShare(config: DMPMap, callback: DMPBridgeCallback) {

  }

  showShareEntrance(config: DMPMap, callback: DMPBridgeCallback) {
    DMPShareComponent.sharedComponent().shareDatas = config.get('buttons')
    DMPShareComponent.sharedComponent().shareCallback = (result: DMPMap) => {
      this.invokeSuccessCallback(callback, result)
    }
    DMPShareComponent.sharedComponent().popShare()
  }

  hideShareEntrance(config: DMPMap, callback: DMPBridgeCallback) {
    DMPShareComponent.sharedComponent().hideShare()
    this.invokeSuccessCallback(callback, null)
  }

  shareWeixinAppmsg(data: DMPMap, callback: DMPBridgeCallback) {
    DMPShareComponent.sharedComponent().shareCallback = (result: DMPMap) => {
      this.invokeSuccessCallback(callback, result)
    }
    DMPShareComponent.sharedComponent().shareData(data, DMPShareSDKChannel.WeChat) //ONEShareSDKChannelWeChat
  }

  shareWeixinTimeline(data: DMPMap, callback: DMPBridgeCallback) {
    DMPShareComponent.sharedComponent().shareCallback = (result: DMPMap) => {
      this.invokeSuccessCallback(callback, result)
    }
    DMPShareComponent.sharedComponent()
      .shareData(data, DMPShareSDKChannel.WeChatFriend) //ONEShareSDKChannelWeChatFriend
  }

  shareQzone(data: DMPMap, callback: DMPBridgeCallback) {
    DMPShareComponent.sharedComponent().shareCallback = (result: DMPMap) => {
      this.invokeSuccessCallback(callback, result)
    }
    DMPShareComponent.sharedComponent().shareData(data, DMPShareSDKChannel.QQZone) //ONEShareSDKChannelQQZone
  }

  shareQqAppmsg(data: DMPMap, callback: DMPBridgeCallback) {
    DMPShareComponent.sharedComponent().shareCallback = (result: DMPMap) => {
      this.invokeSuccessCallback(callback, result)
    }
    DMPShareComponent.sharedComponent().shareData(data, DMPShareSDKChannel.QQ) //ONEShareSDKChannelQQ
  }

  shareAlipayFriend(data: DMPMap, callback: DMPBridgeCallback) {
    DMPShareComponent.sharedComponent().shareCallback = (result: DMPMap) => {
      this.invokeSuccessCallback(callback, result)
    }
    DMPShareComponent.sharedComponent()
      .shareData(data, DMPShareSDKChannel.AliSceneSession) //ONEShareSDKChannelAliSceneSession
  }

  shareAlipayLife(data: DMPMap, callback: DMPBridgeCallback) {
    DMPShareComponent.sharedComponent().shareCallback = (result: DMPMap) => {
      this.invokeSuccessCallback(callback, result)
    }
    DMPShareComponent.sharedComponent()
      .shareData(data, DMPShareSDKChannel.AliSceneTimeLine) //ONEShareSDKChannelAliSceneTimeLine
  }

  shareMessage(data: DMPMap, callback: DMPBridgeCallback) {
    DMPShareComponent.sharedComponent().shareCallback = (result: DMPMap) => {
      this.invokeSuccessCallback(callback, result)
    }
    DMPShareComponent.sharedComponent().shareData(data, DMPShareSDKChannel.Message) //ONEShareSDKChannelMessage
  }

  shareSinaWeibo(data: DMPMap, callback: DMPBridgeCallback) {
    DMPShareComponent.sharedComponent().shareCallback = (result: DMPMap) => {
      this.invokeSuccessCallback(callback, result)
    }
    DMPShareComponent.sharedComponent().shareData(data, DMPShareSDKChannel.WeiBo) //ONEShareSDKChannelWeiBo
  }

  shareFacebook(data: DMPMap, callback: DMPBridgeCallback) {
    DMPShareComponent.sharedComponent().shareCallback = (result: DMPMap) => {
      this.invokeSuccessCallback(callback, result)
    }
    DMPShareComponent.sharedComponent().shareData(data, DMPShareSDKChannel.Facebook) //ONEShareSDKChannelFacebook
  }

  shareTwitter(data: DMPMap, callback: DMPBridgeCallback) {
    DMPShareComponent.sharedComponent().shareCallback = (result: DMPMap) => {
      this.invokeSuccessCallback(callback, result)
    }
    DMPShareComponent.sharedComponent().shareData(data, DMPShareSDKChannel.Twitter) //ONEShareSDKChannelTwitter
  }

  shareWhatsApp(data: DMPMap, callback: DMPBridgeCallback) {
    DMPShareComponent.sharedComponent().shareCallback = (result: DMPMap) => {
      this.invokeSuccessCallback(callback, result)
    }
    DMPShareComponent.sharedComponent().shareData(data, DMPShareSDKChannel.WhatsApp) //ONEShareSDKChannelWhatsApp
  }

  shareEMail(data: DMPMap, callback: DMPBridgeCallback) {
    DMPShareComponent.sharedComponent().shareCallback = (result: DMPMap) => {
      this.invokeSuccessCallback(callback, result)
    }
    DMPShareComponent.sharedComponent().shareData(data, DMPShareSDKChannel.EMail) //ONEShareSDKChannelEMail
  }

  shareSavePicture(data: DMPMap, callback: DMPBridgeCallback) {
    DMPShareComponent.sharedComponent().shareCallback = (result: DMPMap) => {
      this.invokeSuccessCallback(callback, result)
    }
    DMPShareComponent.sharedComponent().shareData(data, DMPShareSDKChannel.SavePicture) //ONEShareSDKChannelSavePicture
  }
}