import UIKit

public final class ScreenAPI: DMPContainerApi {
    private static let SET_KEEP_SCREEN_ON = "setKeepScreenOn"
    private static var keepScreenOwners = Set<String>()

    @BridgeMethod(SET_KEEP_SCREEN_ON)
    var setKeepScreenOn: DMPBridgeMethodHandler = { param, env, callback in
        guard let keepScreenOn = param.getMap().getBool(key: "keepScreenOn") else {
            DMPContainerApi.invokeFailure(callback: callback, param: nil,
                                          errMsg: "setKeepScreenOn:fail invalid keepScreenOn",
                                          completeCarriesResult: true)
            return DMPAsyncResult()
        }
        DispatchQueue.main.async {
            if keepScreenOn {
                ScreenAPI.keepScreenOwners.insert(env.appId)
            } else {
                ScreenAPI.keepScreenOwners.remove(env.appId)
            }
            ScreenAPI.applyKeepScreenState()
            let result = DMPMap(["errMsg": "setKeepScreenOn:ok"])
            DMPContainerApi.invokeSuccess(callback: callback, param: result, completeCarriesResult: true)
        }
        return DMPAsyncResult()
    }

    public static func clearApp(_ appId: String) {
        DispatchQueue.main.async {
            keepScreenOwners.remove(appId)
            applyKeepScreenState()
        }
    }

    private static func applyKeepScreenState() {
        UIApplication.shared.isIdleTimerDisabled = !keepScreenOwners.isEmpty
    }
}
