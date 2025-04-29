import { modDefine, modRequire } from '@dimina/common'
import './pageFrame.scss'
import '@dimina/render'
import '@dimina/components/style'

window.modDefine = modDefine
window.modRequire = modRequire

if (__DEV__)
	import('vconsole').then(({ default: VConsole }) => new VConsole().setSwitchPosition(10, 140))
