package com.didi.dimina.ui.view

import android.Manifest
import android.content.Intent
import android.provider.ContactsContract
import android.app.Activity
import androidx.activity.ComponentActivity
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts
import org.json.JSONObject

/**
 * Author: Doslin
 * 
 * ContactPicker handles all contact-related permission requests and operations.
 * It encapsulates the permission launchers and contact selection functionality.
 */
class ContactPicker(private val activity: ComponentActivity) {
    
    // Permission launchers
    private lateinit var contactPermissionLauncher: ActivityResultLauncher<String>
    private lateinit var chooseContactLauncher: ActivityResultLauncher<Intent>
    private lateinit var writeContactPermissionLauncher: ActivityResultLauncher<String>
    
    // Callbacks
    private var contactApiCallback: ((Boolean, JSONObject) -> Unit)? = null
    private var addContactResultCallback: ((Boolean) -> Unit)? = null
    
    /**
     * Initialize all permission launchers
     */
    init {
        initializePermissionLaunchers()
    }
    
    private fun initializePermissionLaunchers() {
        contactPermissionLauncher = activity.registerForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
            if (granted) {
                launchChooseContact()
            } else {
                contactApiCallback?.invoke(false, JSONObject().apply {
                    put("errMsg", "Permission denied")
                })
                contactApiCallback = null
            }
        }
        
        chooseContactLauncher = activity.registerForActivityResult(ActivityResultContracts.StartActivityForResult()) { result ->
            if (result.resultCode == Activity.RESULT_OK) {
                val contactUri = result.data?.data ?: return@registerForActivityResult
                val contentResolver = activity.contentResolver
                
                val cursor = contentResolver.query(contactUri, null, null, null, null)
                if (cursor?.moveToFirst() == true) {
                    val idIndex = cursor.getColumnIndex(ContactsContract.Contacts._ID)
                    val nameIndex = cursor.getColumnIndex(ContactsContract.Contacts.DISPLAY_NAME)
                    
                    val contactId = cursor.getString(idIndex)
                    val displayName = cursor.getString(nameIndex)
                    
                    val phoneNumbers = mutableListOf<String>()
                    val phoneNumberIndex = cursor.getColumnIndex(ContactsContract.Contacts.HAS_PHONE_NUMBER)
                    val hasPhoneNumber = if (phoneNumberIndex >= 0) cursor.getInt(phoneNumberIndex) > 0 else false
                    if (hasPhoneNumber) {
                        val phonesCursor = contentResolver.query(
                            ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
                            null,
                            "${ContactsContract.CommonDataKinds.Phone.CONTACT_ID} = ?",
                            arrayOf(contactId),
                            null
                        )
                        phonesCursor?.use {
                            while (it.moveToNext()) {
                                val phoneIndex = it.getColumnIndex(ContactsContract.CommonDataKinds.Phone.NUMBER)
                                val phone = it.getString(phoneIndex)
                                phoneNumbers.add(phone)
                            }
                        }
                    }
                    contactApiCallback?.invoke(true, JSONObject().apply {
                        put("displayName", displayName)
                        put("phoneNumberList", phoneNumbers.joinToString(","))
                        put("phoneNumber", phoneNumbers.firstOrNull() ?: "")
                    })
                }
                cursor?.close()
            } else {
                contactApiCallback?.invoke(true, JSONObject().apply {
                    put("errMsg", "User canceled")
                })
            }
            contactApiCallback = null
        }
        
        writeContactPermissionLauncher = activity.registerForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
            addContactResultCallback?.invoke(granted)
            addContactResultCallback = null
        }
    }
    
    /**
     * Request permission to choose a contact and handle the result
     * @param callback Callback to handle the result with contact information
     */
    fun handleChooseContact(callback: (Boolean, JSONObject) -> Unit) {
        contactApiCallback = callback
        contactPermissionLauncher.launch(Manifest.permission.READ_CONTACTS)
    }
    
    /**
     * Request permission to add a contact
     * @param callback Callback to handle the permission result
     */
    fun handleAddContact(callback: (Boolean) -> Unit) {
        addContactResultCallback = callback
        writeContactPermissionLauncher.launch(Manifest.permission.WRITE_CONTACTS)
    }
    
    /**
     * Launch the contact picker directly (assumes permission is already granted)
     */
    fun launchChooseContact() {
        val intent = Intent(Intent.ACTION_PICK, ContactsContract.Contacts.CONTENT_URI)
        chooseContactLauncher.launch(intent)
    }
}
