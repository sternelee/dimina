import { invokeAPI } from '@/api/common'

/**
 * 向蓝牙低功耗设备特征值中写入二进制数据。注意：必须设备的特征支持 write 才可以成功调用。
 * https://developers.weixin.qq.com/miniprogram/dev/api/device/bluetooth-ble/wx.writeBLECharacteristicValue.html
 */
export function writeBLECharacteristicValue(opts) {
	invokeAPI('writeBLECharacteristicValue', opts)
}

/**
 * 协商设置蓝牙低功耗的最大传输单元 (Maximum Transmission Unit, MTU)。需在 wx.createBLEConnection 调用成功后调用。
 * https://developers.weixin.qq.com/miniprogram/dev/api/device/bluetooth-ble/wx.setBLEMTU.html
 */
export function setBLEMTU(opts) {
	invokeAPI('setBLEMTU', opts)
}

/**
 * 读取蓝牙低功耗设备特征值的二进制数据。注意：必须设备的特征支持 read 才可以成功调用。
 * https://developers.weixin.qq.com/miniprogram/dev/api/device/bluetooth-ble/wx.readBLECharacteristicValue.html
 */
export function readBLECharacteristicValue(opts) {
	invokeAPI('readBLECharacteristicValue', opts)
}

/**
 * 监听蓝牙低功耗连接状态改变事件。包括开发者主动连接或断开连接，设备丢失，连接异常断开等等
 * https://developers.weixin.qq.com/miniprogram/dev/api/device/bluetooth-ble/wx.onBLEConnectionStateChange.html
 */
export function onBLEConnectionStateChange(opts) {
	invokeAPI('onBLEConnectionStateChange', opts)
}

/**
 * 监听蓝牙低功耗设备的特征值变化事件。必须先调用 wx.notifyBLECharacteristicValueChange 接口才能接收到设备推送的 notification。
 * https://developers.weixin.qq.com/miniprogram/dev/api/device/bluetooth-ble/wx.onBLECharacteristicValueChange.html
 */
export function onBLECharacteristicValueChange(opts) {
	invokeAPI('onBLECharacteristicValueChange', opts)
}

/**
 * 移除蓝牙低功耗连接状态改变事件的监听函数。不传此参数则移除所有监听函数。
 * https://developers.weixin.qq.com/miniprogram/dev/api/device/bluetooth-ble/wx.offBLEConnectionStateChange.html
 */
export function offBLEConnectionStateChange(opts) {
	invokeAPI('offBLEConnectionStateChange', opts)
}

/**
 * 移除蓝牙低功耗设备的特征值变化事件的全部监听函数
 * https://developers.weixin.qq.com/miniprogram/dev/api/device/bluetooth-ble/wx.offBLECharacteristicValueChange.html
 */
export function offBLECharacteristicValueChange() {
	invokeAPI('offBLECharacteristicValueChange')
}

/**
 * 启用蓝牙低功耗设备特征值变化时的 notify 功能，订阅特征。注意：必须设备的特征支持 notify 或者 indicate 才可以成功调用。
 * 另外，必须先启用 wx.notifyBLECharacteristicValueChange 才能监听到设备 characteristicValueChange 事件
 * https://developers.weixin.qq.com/miniprogram/dev/api/device/bluetooth-ble/wx.notifyBLECharacteristicValueChange.html
 */
export function notifyBLECharacteristicValueChange(opts) {
	invokeAPI('notifyBLECharacteristicValueChange', opts)
}

/**
 * 获取蓝牙低功耗设备所有服务 (service)。
 * https://developers.weixin.qq.com/miniprogram/dev/api/device/bluetooth-ble/wx.getBLEDeviceServices.html
 */
export function getBLEDeviceServices(opts) {
	invokeAPI('getBLEDeviceServices', opts)
}

/**
 * 获取蓝牙低功耗设备的信号强度 (Received Signal Strength Indication, RSSI)
 * https://developers.weixin.qq.com/miniprogram/dev/api/device/bluetooth-ble/wx.getBLEDeviceRSSI.html
 */
export function getBLEDeviceRSSI(opts) {
	invokeAPI('getBLEDeviceRSSI', opts)
}

/**
 * 获取蓝牙低功耗设备某个服务中所有特征 (characteristic)。
 * https://developers.weixin.qq.com/miniprogram/dev/api/device/bluetooth-ble/wx.getBLEDeviceCharacteristics.html
 */
export function getBLEDeviceCharacteristics(opts) {
	invokeAPI('getBLEDeviceCharacteristics', opts)
}

/**
 * 连接蓝牙低功耗设备。
 * 若小程序在之前已有搜索过某个蓝牙设备，并成功建立连接，可直接传入之前搜索获取的 deviceId 直接尝试连接该设备，无需再次进行搜索操作。
 * https://developers.weixin.qq.com/miniprogram/dev/api/device/bluetooth-ble/wx.createBLEConnection.html
 */
export function createBLEConnection(opts) {
	invokeAPI('createBLEConnection', opts)
}

/**
 * 断开与蓝牙低功耗设备的连接。
 * https://developers.weixin.qq.com/miniprogram/dev/api/device/bluetooth-ble/wx.closeBLEConnection.html
 */
export function closeBLEConnection(opts) {
	invokeAPI('closeBLEConnection', opts)
}
