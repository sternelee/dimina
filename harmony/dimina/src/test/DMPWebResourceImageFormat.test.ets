import { describe, expect, it } from '@ohos/hypium'
import { RequestCallback } from '../main/ets/Render/UrlIntercepter/UrlInterceptor'

export default function dmpWebResourceImageFormatTest() {
  describe('DMPWebResource image formats', () => {
    it('recognizesHeicAndHeifResources', 0, () => {
      expect(RequestCallback.isWebResourceRequest('http://127.0.0.1/app/main/photo.heic')).assertTrue()
      expect(RequestCallback.isWebResourceRequest('http://127.0.0.1/app/main/photo.HEIC?version=1#preview')).assertTrue()
      expect(RequestCallback.isWebResourceRequest('http://127.0.0.1/app/main/photo.heif')).assertTrue()
    })

    it('returnsStandardHeicAndHeifMimeTypes', 0, () => {
      expect(RequestCallback.mimeTypeForExtension('heic')).assertEqual('image/heic')
      expect(RequestCallback.mimeTypeForExtension('heif')).assertEqual('image/heif')
      expect(RequestCallback.mimeTypeForExtension('unknown', 'image/*')).assertEqual('image/*')
    })

    it('transcodesHeifFamilyImagesForArkWeb', 0, () => {
      expect(RequestCallback.requiresHeifTranscode('heic')).assertTrue()
      expect(RequestCallback.requiresHeifTranscode('HEIF')).assertTrue()
      expect(RequestCallback.requiresHeifTranscode('jpeg')).assertFalse()
    })
  })
}
