import { DMPContainerBridgesModule } from './DMPContainerBridgesModule'
import { DMPBridgeCallback } from './DMPTSUtil'
import { scanBarcode, scanCore } from '@kit.ScanKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { DMPLogger } from '../EventTrack/DMPLogger'
import { DMPMap } from '../Utils/DMPMap';
import { DMPContextUtils } from '../Utils/DMPContextUtils';

export class DMPContainerBridgesModuleScanCode extends DMPContainerBridgesModule {
  getExportMethods(): string[] {
    return ['scanCode'];
  }

  scanCode(data: DMPMap, callback: DMPBridgeCallback) {
    DMPLogger.i(`  scanCode ->> start`)
    let options: scanBarcode.ScanOptions =
      { scanTypes: [scanCore.ScanType.TWO_D_CODE], enableMultiMode: false, enableAlbum: false };
    try {
      scanBarcode.startScanForResult(DMPContextUtils.getUIAbilityContext(), options,
        (error: BusinessError, result: scanBarcode.ScanResult) => {
          if (error) {
            DMPLogger.i(`  scanCode ->> error`)
            this.invokeFailureCallback(callback, null, `Error -> code ${error.code}  ${error.message}`)
            return
          }
          let scanResult = new DMPMap()
          scanResult.set("result", result.originalValue)
          DMPLogger.i(`  scanCode result ->> ${scanResult.get("result")}`)
          this.invokeSuccessCallback(callback, scanResult)
        });
    } catch (error) {
      DMPLogger.i(`   scanCode ->> error`)
      this.invokeFailureCallback(callback, null, `Error -> code ${error.code}  ${error.message}`)
    }
  }
}