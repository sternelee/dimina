import UIKit

public final class ScreenAPI: DMPContainerApi {
    private static let SET_KEEP_SCREEN_ON = "setKeepScreenOn"

    @BridgeMethod(SET_KEEP_SCREEN_ON)
    var setKeepScreenOn: DMPBridgeMethodHandler = { param, _, callback in
        guard let keepScreenOn = param.getMap().getBool(key: "keepScreenOn") else {
            DMPContainerApi.invokeFailure(callback: callback, param: nil,
                                          errMsg: "setKeepScreenOn:fail invalid keepScreenOn",
                                          completeCarriesResult: true)
            return DMPAsyncResult()
        }
        DispatchQueue.main.async {
            UIApplication.shared.isIdleTimerDisabled = keepScreenOn
            let result = DMPMap(["errMsg": "setKeepScreenOn:ok"])
            DMPContainerApi.invokeSuccess(callback: callback, param: result, completeCarriesResult: true)
        }
        return DMPAsyncResult()
    }
}
