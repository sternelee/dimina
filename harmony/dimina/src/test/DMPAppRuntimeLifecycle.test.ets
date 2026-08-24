import { describe, expect, it } from '@ohos/hypium'
import { DMPAppRuntimeLifecycle } from '../main/ets/DApp/utils/DMPAppRuntimeLifecycle'

export default function dmpAppRuntimeLifecycleTest() {
  describe('DMPAppRuntimeLifecycle', () => {
    it('requiresACompleteRuntimeRebuildAfterClose', 0, () => {
      const lifecycle = new DMPAppRuntimeLifecycle()

      expect(lifecycle.beginClose()).assertTrue()
      expect(lifecycle.isClosing).assertTrue()
      expect(lifecycle.shouldDeferLaunch()).assertTrue()

      lifecycle.markDestroyed()
      expect(lifecycle.isDestroyed).assertTrue()
      expect(lifecycle.beginClose()).assertFalse()

      lifecycle.markReady()
      expect(lifecycle.isDestroyed).assertFalse()
      expect(lifecycle.shouldDeferLaunch()).assertFalse()
      expect(lifecycle.beginClose()).assertTrue()
    })

    it('returnsToReadyWhenCloseFailsBeforeDestroyingTheRuntime', 0, () => {
      const lifecycle = new DMPAppRuntimeLifecycle()

      lifecycle.beginClose()
      lifecycle.cancelClose()

      expect(lifecycle.isClosing).assertFalse()
      expect(lifecycle.isDestroyed).assertFalse()
      expect(lifecycle.beginClose()).assertTrue()
    })
  })
}
