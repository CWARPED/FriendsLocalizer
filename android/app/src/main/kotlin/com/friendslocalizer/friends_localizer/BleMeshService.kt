// UNVERIFIED: requires on-device build/test (Plan 3 Task D1)
package com.friendslocalizer.friends_localizer

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattDescriptor
import android.bluetooth.BluetoothGattServer
import android.bluetooth.BluetoothGattServerCallback
import android.bluetooth.BluetoothGattService
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.bluetooth.le.AdvertiseCallback
import android.bluetooth.le.AdvertiseData
import android.bluetooth.le.AdvertiseSettings
import android.bluetooth.le.BluetoothLeAdvertiser
import android.bluetooth.le.BluetoothLeScanner
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.os.ParcelUuid
import android.util.Log
import java.util.UUID

/**
 * Service de premier plan qui exécute le mesh BLE : advertise un Service UUID,
 * expose une caractéristique NOTIFY/WRITE (rôle peripheral), et scanne +
 * connecte + s'abonne aux pairs (rôle central). `broadcast` notifie tous les
 * centraux abonnés. Les trames reçues et les événements de voisinage sont
 * remontés via [listener].
 */
class BleMeshService : Service() {

    companion object {
        val SERVICE_UUID: UUID = UUID.fromString("0000fe40-0000-1000-8000-00805f9b34fb")
        val CHAR_UUID: UUID = UUID.fromString("0000fe41-0000-1000-8000-00805f9b34fb")
        val CCCD_UUID: UUID = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")
        const val CHANNEL_ID = "fl_ble"
        const val NOTIF_ID = 42

        /** Pont vers le plugin pour remonter les événements vers Dart. */
        var listener: BleMeshListener? = null

        /** Instance courante du service, pour que le plugin appelle `broadcast`. */
        @Volatile var instance: BleMeshService? = null
    }

    private lateinit var adapter: BluetoothAdapter
    private var advertiser: BluetoothLeAdvertiser? = null
    private var scanner: BluetoothLeScanner? = null
    private var gattServer: BluetoothGattServer? = null
    private var notifyChar: BluetoothGattCharacteristic? = null

    private val subscribers = mutableSetOf<BluetoothDevice>()        // centraux abonnés (peripheral)
    private val centralGatts = mutableMapOf<String, BluetoothGatt>() // connexions sortantes (central)

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        // Android 14 (API 34) exige le type de service dans l'appel startForeground
        // dès lors que le manifeste déclare foregroundServiceType.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(
                NOTIF_ID, buildNotification(),
                ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE
            )
        } else {
            startForeground(NOTIF_ID, buildNotification())
        }
        val mgr = getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        adapter = mgr.adapter
        startPeripheral(mgr)
        startCentral()
        instance = this
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int = START_STICKY

    override fun onDestroy() {
        try { advertiser?.stopAdvertising(advertiseCallback) } catch (_: Exception) {}
        try { scanner?.stopScan(scanCallback) } catch (_: Exception) {}
        gattServer?.close()
        centralGatts.values.forEach { it.close() }
        centralGatts.clear()
        instance = null
        super.onDestroy()
    }

    // ---- Rôle PERIPHERAL : advertise + GATT server ----
    private fun startPeripheral(mgr: BluetoothManager) {
        val server = mgr.openGattServer(this, gattServerCallback)
        val service = BluetoothGattService(SERVICE_UUID, BluetoothGattService.SERVICE_TYPE_PRIMARY)
        val ch = BluetoothGattCharacteristic(
            CHAR_UUID,
            BluetoothGattCharacteristic.PROPERTY_NOTIFY or BluetoothGattCharacteristic.PROPERTY_WRITE,
            BluetoothGattCharacteristic.PERMISSION_WRITE
        )
        val cccd = BluetoothGattDescriptor(
            CCCD_UUID,
            BluetoothGattDescriptor.PERMISSION_READ or BluetoothGattDescriptor.PERMISSION_WRITE
        )
        ch.addDescriptor(cccd)
        service.addCharacteristic(ch)
        server.addService(service)
        gattServer = server
        notifyChar = ch

        advertiser = adapter.bluetoothLeAdvertiser
        val settings = AdvertiseSettings.Builder()
            .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
            .setConnectable(true)
            .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_HIGH)
            .build()
        val data = AdvertiseData.Builder()
            .addServiceUuid(ParcelUuid(SERVICE_UUID))
            .build()
        advertiser?.startAdvertising(settings, data, advertiseCallback)
    }

    private val advertiseCallback = object : AdvertiseCallback() {
        override fun onStartFailure(errorCode: Int) {
            Log.e("BleMesh", "advertise failed: $errorCode")
        }
    }

    private val gattServerCallback = object : BluetoothGattServerCallback() {
        override fun onDescriptorWriteRequest(
            device: BluetoothDevice, requestId: Int, descriptor: BluetoothGattDescriptor,
            preparedWrite: Boolean, responseNeeded: Boolean, offset: Int, value: ByteArray?
        ) {
            if (descriptor.uuid == CCCD_UUID) {
                val enabling = value != null &&
                    value.contentEquals(BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE)
                if (enabling) subscribers.add(device) else subscribers.remove(device)
                if (responseNeeded) {
                    gattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, offset, null)
                }
            }
        }

        override fun onCharacteristicWriteRequest(
            device: BluetoothDevice, requestId: Int, characteristic: BluetoothGattCharacteristic,
            preparedWrite: Boolean, responseNeeded: Boolean, offset: Int, value: ByteArray?
        ) {
            if (characteristic.uuid == CHAR_UUID && value != null) {
                listener?.onFrame(value)
            }
            if (responseNeeded) {
                gattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, offset, null)
            }
        }
    }

    // ---- Rôle CENTRAL : scan + connect + subscribe ----
    private fun startCentral() {
        scanner = adapter.bluetoothLeScanner
        val filter = ScanFilter.Builder()
            .setServiceUuid(ParcelUuid(SERVICE_UUID)).build()
        val settings = ScanSettings.Builder()
            .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY).build()
        scanner?.startScan(listOf(filter), settings, scanCallback)
    }

    private val scanCallback = object : ScanCallback() {
        override fun onScanResult(callbackType: Int, result: ScanResult) {
            val device = result.device
            if (centralGatts.containsKey(device.address)) return
            // TRANSPORT_LE force le GATT en BLE (évite un fallback BR/EDR sur les
            // appareils dual-mode, qui rendrait le service GATT invisible).
            centralGatts[device.address] =
                device.connectGatt(this@BleMeshService, false, gattClientCallback,
                    BluetoothDevice.TRANSPORT_LE)
        }

        override fun onScanFailed(errorCode: Int) {
            Log.e("BleMesh", "scan failed: $errorCode")
        }
    }

    private val gattClientCallback = object : BluetoothGattCallback() {
        override fun onConnectionStateChange(gatt: BluetoothGatt, status: Int, newState: Int) {
            if (newState == BluetoothProfile.STATE_CONNECTED) {
                gatt.discoverServices()
            } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                centralGatts.remove(gatt.device.address)
                gatt.close()
            }
        }

        override fun onServicesDiscovered(gatt: BluetoothGatt, status: Int) {
            val ch = gatt.getService(SERVICE_UUID)?.getCharacteristic(CHAR_UUID) ?: return
            gatt.setCharacteristicNotification(ch, true)
            val cccd = ch.getDescriptor(CCCD_UUID) ?: return
            @Suppress("DEPRECATION")
            cccd.value = BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
            @Suppress("DEPRECATION")
            gatt.writeDescriptor(cccd)
        }

        override fun onDescriptorWrite(
            gatt: BluetoothGatt, descriptor: BluetoothGattDescriptor, status: Int
        ) {
            if (descriptor.uuid == CCCD_UUID) listener?.onNeighbor() // abonnement confirmé = voisin
        }

        @Deprecated("Deprecated in API 33")
        override fun onCharacteristicChanged(
            gatt: BluetoothGatt, characteristic: BluetoothGattCharacteristic
        ) {
            if (characteristic.uuid == CHAR_UUID) {
                @Suppress("DEPRECATION")
                characteristic.value?.let { listener?.onFrame(it) }
            }
        }
    }

    // ---- Diffusion : notifier tous les centraux abonnés ----
    fun broadcast(frame: ByteArray) {
        val ch = notifyChar ?: return
        val server = gattServer ?: return
        @Suppress("DEPRECATION")
        ch.value = frame
        for (device in subscribers.toList()) {
            try {
                @Suppress("DEPRECATION")
                server.notifyCharacteristicChanged(device, ch, false)
            } catch (_: Exception) {}
        }
    }

    private fun buildNotification(): Notification {
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            nm.createNotificationChannel(
                NotificationChannel(CHANNEL_ID, "FriendsLocalizer Mesh", NotificationManager.IMPORTANCE_LOW)
            )
        }
        return Notification.Builder(this, CHANNEL_ID)
            .setContentTitle("FriendsLocalizer")
            .setContentText("Mesh Bluetooth actif")
            .setSmallIcon(android.R.drawable.stat_sys_data_bluetooth)
            .build()
    }
}

/** Pont d'événements implémenté par le plugin (remonte vers Dart). */
interface BleMeshListener {
    fun onFrame(frame: ByteArray)
    fun onNeighbor()
}
