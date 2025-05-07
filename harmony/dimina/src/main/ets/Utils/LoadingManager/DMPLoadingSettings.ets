export interface DMPLoadingSettings {
  /**
   * msg default is ''
   */
  msg?: string
  /**
   * alignment default is center
   */
  alignment?: DialogAlignment
  /**
   * offset default is （0，0）
   */
  offset?: Offset
  /**
   * tintColor, image & LoadingProgress color, default is white
   */
  tintColor?: ResourceColor
  /**
   * textColor default is white
   */
  textColor?: ResourceColor
  /**
   * hideDelay default is 2000 ms
   */
  hideDelay?: number
  /**
   * fontSize default is 16fp
   */
  fontSize?: number | string | Resource
  /**
   * backgroundColor default is #cc000000
   */
  backgroundColor?: ResourceColor
  /**
   * maskColor default is Transparent
   */
  maskColor?: ResourceColor
  /**
   * borderRadius default is 10
   */
  borderRadius?: Length | BorderRadiuses
  /**
   * transition default is undefined
   */
  transition?: TransitionEffect
  /**
   * success image 最好是svg格式
   */
  successSrc?: PixelMap | ResourceStr | DrawableDescriptor
  /**
   * failure image 最好是svg格式
   */
  failureSrc?: PixelMap | ResourceStr | DrawableDescriptor
  /**
   * info image 最好是svg格式
   */
  infoSrc?: PixelMap | ResourceStr | DrawableDescriptor
  /**
   * warn image 最好是svg格式
   */
  warnSrc?: PixelMap | ResourceStr | DrawableDescriptor
  /**
   * Icon progress
   */
  iconProgress?: PixelMap | ResourceStr | DrawableDescriptor
  /**
   * 点击弹框外部是否隐藏hud 默认是false
   */
  hideOnTouchOutside?: boolean
  /**
   * 系统返回时是否隐藏hud 默认是false
   */
  hideOnSystemBack?: boolean
  /**
   * 是否显示在subWindow之上 默认是false
   */
  showInSubWindow?: boolean
}

export class DMPLoadingDialogSettings {
  msg: string = ''
  alignment: DialogAlignment = DialogAlignment.Center
  offset: Offset = { dx: 0, dy: 0 }
  tintColor: ResourceColor = Color.White
  textColor: ResourceColor = Color.White
  hideDelay: number = 2000
  fontSize: number | string | Resource = '16fp'
  backgroundColor: ResourceColor = '#cc000000'
  maskColor: ResourceColor = Color.Transparent
  borderRadius: Length | BorderRadiuses = 10
  transition: TransitionEffect | undefined = undefined
  successSrc: PixelMap | ResourceStr | DrawableDescriptor = $r('app.media.loading_success')
  failureSrc: PixelMap | ResourceStr | DrawableDescriptor = $r('app.media.loading_error')
  infoSrc: PixelMap | ResourceStr | DrawableDescriptor = $r('app.media.loading_info')
  warnSrc: PixelMap | ResourceStr | DrawableDescriptor = $r('app.media.loading_warn')
  iconProgress: PixelMap | ResourceStr | DrawableDescriptor = $r('app.media.launch_loading_l')
  hideOnTouchOutside: boolean = false
  hideOnSystemBack: boolean = false
  showInSubWindow: boolean = false
}

export let loadingDialogGlobalSettings = new DMPLoadingDialogSettings()