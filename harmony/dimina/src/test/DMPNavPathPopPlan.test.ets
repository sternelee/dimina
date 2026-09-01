import { describe, expect, it } from '@ohos/hypium'
import { DMPNavPathPopPlan } from '../main/ets/Navigator/DRouter'

export default function dmpNavPathPopPlanTest() {
  describe('DMPNavPathPopPlan', () => {
    it('keepsTheDestinationImmediatelyBelowTheOwnedEntries', 0, () => {
      expect(DMPNavPathPopPlan.targetIndex(5, 1)).assertEqual(3)
      expect(DMPNavPathPopPlan.targetIndex(5, 3)).assertEqual(1)
    })

    it('returnsToNavigationHomeWhenEveryDestinationIsOwned', 0, () => {
      expect(DMPNavPathPopPlan.targetIndex(3, 3)).assertEqual(-1)
    })

    it('neverPopsPastTheAvailableNavigationStack', 0, () => {
      expect(DMPNavPathPopPlan.targetIndex(2, 99)).assertEqual(-1)
    })

    it('skipsTheNativeOperationWhenThereIsNothingToPop', 0, () => {
      expect(DMPNavPathPopPlan.targetIndex(0, 1)).assertUndefined()
      expect(DMPNavPathPopPlan.targetIndex(4, 0)).assertUndefined()
    })
  })
}
