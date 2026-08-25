import { describe, expect, it } from '@ohos/hypium'
import { DMPContainerBridgesModule } from '../main/ets/Bridges/DMPContainerBridgesModule'
import { DMPBridgeCallbackType } from '../main/ets/Bridges/DMPTSUtil'
import { WorkerAppData } from '../main/ets/Service/DMPSendableObjects'
import { DMPMap } from '../main/ets/Utils/DMPMap'

class TestContainerBridgesModule extends DMPContainerBridgesModule {
  constructor() {
    super(new WorkerAppData())
  }

  getExportMethods(): Array<string> {
    return []
  }
}

export default function dmpContainerCallbackContractTest() {
  describe('DMPContainer callback contract', () => {
    it('passesTheSameResultIntoCompleteByDefault', 0, () => {
      const module = new TestContainerBridgesModule()
      const result = new DMPMap({ 'errMsg': 'example:ok' })
      const callbackTypes: Array<DMPBridgeCallbackType> = []
      const callbackResults: Array<DMPMap> = []

      module.invokeSuccessCallback((args, type) => {
        callbackTypes.push(type)
        callbackResults.push(args)
      }, result)

      expect(callbackTypes.length).assertEqual(2)
      expect(callbackTypes[0]).assertEqual(DMPBridgeCallbackType.Success)
      expect(callbackTypes[1]).assertEqual(DMPBridgeCallbackType.Complete)
      expect(callbackResults[0] === result).assertTrue()
      expect(callbackResults[1] === result).assertTrue()
    })
  })
}
