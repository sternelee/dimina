/**
 * Audio 实体
 */
export class InnerAudioTask {
  audioId: string = ''
  paused: boolean = false
  startTime: number = 0
  currentTime: number = 0
  duration: number = 0
  obeyMuteSwitch: boolean = false
  autoPlay: boolean = false
  loop: boolean = false
  src: string = ''
}
