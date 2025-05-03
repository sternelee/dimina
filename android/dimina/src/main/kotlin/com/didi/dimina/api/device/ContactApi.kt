package com.didi.dimina.api.device

import android.content.ContentProviderOperation
import android.provider.ContactsContract
import androidx.activity.ComponentActivity
import com.didi.dimina.api.APIResult
import com.didi.dimina.api.BaseApiHandler
import com.didi.dimina.api.NoneResult
import com.didi.dimina.common.ApiUtils
import com.didi.dimina.ui.container.DiminaActivity
import org.json.JSONObject

/**
 * Device - Contact API
 * Author: Doslin
 */
class ContactApi : BaseApiHandler() {
     private companion object {
        const val CHOOSE_CONTACT = "chooseContact"
        const val ADD_PHONE_CONTACT = "addPhoneContact"
    }

    override val apiNames = setOf(
        CHOOSE_CONTACT,
        ADD_PHONE_CONTACT,
    )

    override fun handleAction(activity: DiminaActivity, appId: String, apiName: String, params: JSONObject, responseCallback: (String) -> Unit): APIResult {
        return when (apiName) {
            CHOOSE_CONTACT -> {
                activity.handleChooseContact {success, result ->
                    if (success) {
                        result.put("errMsg", "$CHOOSE_CONTACT:ok")
                        ApiUtils.invokeSuccess(params, result, responseCallback)
                    } else {
                        result.put("errMsg", "$CHOOSE_CONTACT:fail ${result.getString("errMsg")}")
                        ApiUtils.invokeFail(params, result, responseCallback)
                    }
                    ApiUtils.invokeComplete(params, responseCallback)
                }
                NoneResult()
            }
            ADD_PHONE_CONTACT -> {
                activity.handleAddContact { success ->
                    if (success) {
                        doAddContact(activity, params, responseCallback)
                    } else {
                        ApiUtils.invokeFail(params, JSONObject().apply {
                            put("errMsg", "$ADD_PHONE_CONTACT:fail Permission denied")
                        }, responseCallback)
                    }
                }
                NoneResult()
            }
            else ->
                super.handleAction(activity, appId, apiName, params, responseCallback)
        }
    }

    private fun doAddContact(activity: ComponentActivity, params: JSONObject, responseCallback: (String) -> Unit) {
        val firstName = params.optString("firstName")
        if (firstName.isNotEmpty()) {
            val middleName = params.optString("middleName")
            val lastName = params.optString("lastName")
            val ops = ArrayList<ContentProviderOperation>()
            ops.add(
                ContentProviderOperation.newInsert(ContactsContract.RawContacts.CONTENT_URI)
                    .withValue(ContactsContract.RawContacts.ACCOUNT_TYPE, null)
                    .withValue(ContactsContract.RawContacts.ACCOUNT_NAME, null)
                    .build()
            )
            ops.add(
                ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                    .withValueBackReference(ContactsContract.Data.RAW_CONTACT_ID, 0)
                    .withValue(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.StructuredName.CONTENT_ITEM_TYPE)
                    .withValue(ContactsContract.CommonDataKinds.StructuredName.GIVEN_NAME, firstName)
                    .withValue(ContactsContract.CommonDataKinds.StructuredName.MIDDLE_NAME, middleName)
                    .withValue(ContactsContract.CommonDataKinds.StructuredName.FAMILY_NAME, lastName)
                    .build()
            )

            val remark = params.optString("remark")
            if (remark.isNotEmpty()) {
                ops.add(
                    ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                        .withValueBackReference(ContactsContract.Data.RAW_CONTACT_ID, 0)
                        .withValue(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.Note.CONTENT_ITEM_TYPE)
                        .withValue(ContactsContract.CommonDataKinds.Note.NOTE, remark)
                        .build()
                )
            }

            val mobilePhoneNumber = params.optString("mobilePhoneNumber")
            if (mobilePhoneNumber.isNotEmpty()) {
                ops.add(
                    ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                        .withValueBackReference(ContactsContract.Data.RAW_CONTACT_ID, 0)
                        .withValue(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.Phone.CONTENT_ITEM_TYPE)
                        .withValue(ContactsContract.CommonDataKinds.Phone.NUMBER, mobilePhoneNumber)
                        .withValue(ContactsContract.CommonDataKinds.Phone.TYPE, ContactsContract.CommonDataKinds.Phone.TYPE_MOBILE)
                        .build()
                )
            }

            val nickName = params.optString("nickName")
            if (nickName.isNotEmpty()) {
                ops.add(
                    ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                        .withValueBackReference(ContactsContract.Data.RAW_CONTACT_ID, 0)
                        .withValue(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.Nickname.CONTENT_ITEM_TYPE)
                        .withValue(ContactsContract.CommonDataKinds.Nickname.NAME, nickName)
                        .build()
                )
            }

            try {
                activity.contentResolver.applyBatch(ContactsContract.AUTHORITY, ops)
                ApiUtils.invokeSuccess(params, JSONObject().apply {
                    put("errMsg", "$ADD_PHONE_CONTACT:ok")
                }, responseCallback)
            } catch (e: Exception) {
                ApiUtils.invokeFail(params, JSONObject().apply {
                    put("errMsg", "$ADD_PHONE_CONTACT:fail ${e.message}")
                }, responseCallback)
            } finally {
                ApiUtils.invokeComplete(params, responseCallback)
            }
        } else {
            ApiUtils.invokeFail(params, JSONObject().apply {
                put("errMsg", "$ADD_PHONE_CONTACT:fail firstName is required")
            }, responseCallback)
            ApiUtils.invokeComplete(params, responseCallback)
        }
    }
}