package com.didi.dimina.api

import com.didi.dimina.common.LogUtils
import com.didi.dimina.ui.container.DiminaActivity
import org.json.JSONObject

/**
 * API Registry to manage all API handlers
 * Author: Doslin
 */
class ApiRegistry {
    private val tag = "ApiRegistry"
    private val apiHandlers = mutableMapOf<String, ApiHandler>()

    /**
     * Registers an API handler
     */
    fun register(name: String, handler: ApiHandler) {
        apiHandlers[name] = handler
    }
    
    /**
     * Invokes an API
     * 
     * @param apiName The name of the API to invoke
     * @param params Parameters for the API call
     * @return True if API was successfully invoked, false otherwise
     */
    fun invoke(
        activity: DiminaActivity,
        appId: String,
        apiName: String, 
        params: JSONObject,
        responseCallback: (String) -> Unit,
    ): APIResult {
        val handler = apiHandlers[apiName]
        if (handler == null) {
            LogUtils.e(tag,  "API not found: $apiName")
            return NoneResult()
        }
        return handler.handleAction(activity, appId, apiName, params, responseCallback)
    }
    
    /**
     * Clears all API handlers
     */
    fun clear() {
        apiHandlers.clear()
    }
    
    /**
     * Gets a set of all registered API names
     * 
     * @return Set of all registered API names
     */
    fun getRegisteredApiNames(): Set<String> {
        return apiHandlers.keys
    }
}
