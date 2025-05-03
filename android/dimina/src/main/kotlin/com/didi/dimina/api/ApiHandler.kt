package com.didi.dimina.api

import com.didi.dimina.common.ApiUtils
import com.didi.dimina.engine.qjs.JSValue
import com.didi.dimina.ui.container.DiminaActivity
import org.json.JSONObject


sealed class APIResult
data class SyncResult(val value: JSValue) : APIResult()
data class AsyncResult(val value: JSONObject) : APIResult()
data class NoneResult(val value: Any? = null) : APIResult()

/**
 * Base interface for all API handlers
 * Author: Doslin
 */
interface ApiHandler {
    /**
     * Handles an API call
     * 
     * @param params Parameters for the API call
     * @return True if API was successfully handled, false otherwise
     */
    fun handleAction(
        activity: DiminaActivity,
        appId: String,
        apiName: String,
        params: JSONObject,
        responseCallback: (String) -> Unit,
    ): APIResult
    
}

/**
 * Abstract base class for API handlers
 */
abstract class BaseApiHandler : ApiHandler {

    /**
     * Set of API names that this handler can process
     */
    protected open val apiNames: Set<String> = emptySet()
    
    override fun handleAction(activity: DiminaActivity, appId: String, apiName: String, params: JSONObject, responseCallback: (String) -> Unit): APIResult {
        return ApiUtils.createUnsupportedErrorResponse(apiName)
    }

    /**
     * Registers all API names with the registry
     */
    fun registerWith(registry: ApiRegistry) {
        // Register each API name
        apiNames.forEach { apiName ->
            registry.register(apiName, this)
        }
    }
}
