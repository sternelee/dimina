
import { DMPMap } from '../../Utils/DMPMap'

export class DMPNavigationModel {
  titleText: string = '';
  backgroundColor?: string;
  textStyle?: string;
  capsuleButton?: string;
  titleColor?: string;
  hideNaviBar: boolean = false;

  valueFromMap(dict: DMPMap) {
    this.titleText = dict.get('navigationBarTitleText') ?? '标题';
    this.backgroundColor = dict.get('navigationBarBackgroundColor');
    this.textStyle = dict.get('backgroundTextStyle');
    this.capsuleButton = dict.get('capsuleButton');
  }

  isShowCapsuleButton(): boolean {
    if (this.capsuleButton === 'show') {
      return true;
    }
    return false;
  }

  resultTitleColor(): string {
    if (this.titleColor) {
      return this.titleColor;
    }
    if (this.textStyle === 'white') {
      return '#FFFFFF'
    }
    return '#000000'
  }
}