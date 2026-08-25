import { beforeEach, describe, expect, it, vi } from 'vitest'

vi.mock('@/api/common', () => ({
	invokeAPI: vi.fn(),
}))

import { callback } from '@dimina/common'
import { invokeAPI } from '@/api/common'
import { getImageInfo, previewMedia } from '../src/api/core/media/image/index.js'
import {
	chooseVideo,
	compressVideo,
	getVideoInfo,
	saveVideoToPhotosAlbum,
} from '../src/api/core/media/video/index.js'
import {
	offNetworkStatusChange,
	onNetworkStatusChange,
} from '../src/api/core/device/network/index.js'
import { setKeepScreenOn } from '../src/api/core/device/screen/index.js'
import { authorize } from '../src/api/core/open-api/authorize/index.js'
import { getSetting, openSetting } from '../src/api/core/open-api/setting/index.js'

describe('media and device api adapters', () => {
	beforeEach(() => {
		offNetworkStatusChange()
		vi.mocked(invokeAPI).mockReset()
		callback.remove()
	})

	it.each([
		[getImageInfo, 'getImageInfo', { src: 'difile://image.jpg' }],
		[previewMedia, 'previewMedia', { sources: [{ url: 'difile://image.jpg' }] }],
		[chooseVideo, 'chooseVideo', { sourceType: ['album'] }],
		[getVideoInfo, 'getVideoInfo', { src: 'difile://video.mp4' }],
		[saveVideoToPhotosAlbum, 'saveVideoToPhotosAlbum', { filePath: 'difile://video.mp4' }],
		[compressVideo, 'compressVideo', { src: 'difile://video.mp4' }],
		[getSetting, 'getSetting', {}],
		[openSetting, 'openSetting', {}],
		[authorize, 'authorize', { scope: 'scope.camera' }],
		[setKeepScreenOn, 'setKeepScreenOn', { keepScreenOn: true }],
	])('forwards %s to the native bridge', (api, name, options) => {
		api(options)
		expect(invokeAPI).toHaveBeenCalledWith(name, options)
	})

	it('shares one native network subscription across listeners', () => {
		const first = vi.fn()
		const second = vi.fn()
		onNetworkStatusChange(first)
		onNetworkStatusChange(second)

		expect(invokeAPI).toHaveBeenCalledTimes(1)
		const params = vi.mocked(invokeAPI).mock.calls[0][1]
		callback.invoke(params.callbackId, { isConnected: true, networkType: 'wifi' })

		expect(first).toHaveBeenCalledWith({ isConnected: true, networkType: 'wifi' })
		expect(second).toHaveBeenCalledWith({ isConnected: true, networkType: 'wifi' })
	})

	it('keeps the native network subscription until the last listener is removed', () => {
		const first = vi.fn()
		const second = vi.fn()
		onNetworkStatusChange(first)
		onNetworkStatusChange(second)
		offNetworkStatusChange(first)
		expect(invokeAPI).toHaveBeenCalledTimes(1)

		offNetworkStatusChange(second)
		expect(invokeAPI).toHaveBeenLastCalledWith(
			'offNetworkStatusChange',
			expect.objectContaining({ keep: true }),
		)
	})
})
