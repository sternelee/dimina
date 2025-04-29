import { invokeAPI } from '@/api/common'

export function getPrivacySetting(opts) {
	invokeAPI('getPrivacySetting', opts)
}
