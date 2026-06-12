// UNVERIFIED: requires macOS + Xcode + 2 iPhones (Plan 3 Task D1)
import Flutter
import CoreBluetooth

/// Rôle double : CBPeripheralManager (advertise service + caractéristique NOTIFY,
/// reçoit les abonnements) et CBCentralManager (scan → connect → subscribe).
/// `broadcast` = updateValue vers les centraux abonnés. Réception = didUpdateValue.
class BleMeshPlugin: NSObject, FlutterPlugin, FlutterStreamHandler,
    CBPeripheralManagerDelegate, CBCentralManagerDelegate, CBPeripheralDelegate {

    static let serviceUUID = CBUUID(string: "FE40")
    static let charUUID = CBUUID(string: "FE41")

    private var events: FlutterEventSink?
    private var peripheralManager: CBPeripheralManager!
    private var centralManager: CBCentralManager!
    private var notifyChar: CBMutableCharacteristic!
    private var subscribedCentrals = [CBCentral]()
    private var peripherals = [UUID: CBPeripheral]()

    static func register(with registrar: FlutterPluginRegistrar) {
        let instance = BleMeshPlugin()
        let method = FlutterMethodChannel(name: "fl/ble", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: method)
        let event = FlutterEventChannel(name: "fl/ble/events", binaryMessenger: registrar.messenger())
        event.setStreamHandler(instance)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "start":
            peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
            centralManager = CBCentralManager(delegate: self, queue: nil)
            result(nil)
        case "stop":
            peripheralManager?.stopAdvertising()
            centralManager?.stopScan()
            result(nil)
        case "broadcast":
            if let data = (call.arguments as? FlutterStandardTypedData)?.data {
                broadcast(data)
            }
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    func onListen(withArguments arguments: Any?, eventSink: @escaping FlutterEventSink) -> FlutterError? {
        events = eventSink
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        events = nil
        return nil
    }

    private func broadcast(_ data: Data) {
        guard let ch = notifyChar else { return }
        // nil = tous les abonnés
        peripheralManager.updateValue(data, for: ch, onSubscribedCentrals: nil)
    }

    // MARK: - Peripheral
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        guard peripheral.state == .poweredOn else { return }
        let ch = CBMutableCharacteristic(
            type: Self.charUUID,
            properties: [.notify, .write],
            value: nil,
            permissions: [.writeable])
        let service = CBMutableService(type: Self.serviceUUID, primary: true)
        service.characteristics = [ch]
        peripheral.add(service)
        notifyChar = ch
        peripheral.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [Self.serviceUUID]])
    }

    func peripheralManager(_ peripheral: CBPeripheralManager,
                           central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        subscribedCentrals.append(central)
    }

    func peripheralManager(_ peripheral: CBPeripheralManager,
                           central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        subscribedCentrals.removeAll { $0.identifier == central.identifier }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager,
                           didReceiveWrite requests: [CBATTRequest]) {
        for req in requests {
            if let value = req.value { emitFrame(value) }
            peripheral.respond(to: req, withResult: .success)
        }
    }

    // MARK: - Central
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard central.state == .poweredOn else { return }
        central.scanForPeripherals(withServices: [Self.serviceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        if peripherals[peripheral.identifier] != nil { return }
        peripherals[peripheral.identifier] = peripheral
        peripheral.delegate = self
        central.connect(peripheral, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices([Self.serviceUUID])
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        peripherals.removeValue(forKey: peripheral.identifier)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let service = peripheral.services?.first(where: { $0.uuid == Self.serviceUUID }) else { return }
        peripheral.discoverCharacteristics([Self.charUUID], for: service)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        guard let ch = service.characteristics?.first(where: { $0.uuid == Self.charUUID }) else { return }
        peripheral.setNotifyValue(true, for: ch)
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        // Émettre le voisin SEULEMENT une fois l'abonnement confirmé (sinon le
        // store-and-forward ré-émet avant que le tuyau de notification soit ouvert).
        if characteristic.uuid == Self.charUUID, characteristic.isNotifying {
            emitNeighbor()
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        if characteristic.uuid == Self.charUUID, let value = characteristic.value {
            emitFrame(value)
        }
    }

    // MARK: - Vers Dart
    private func emitFrame(_ data: Data) {
        events?(["type": "frame", "data": FlutterStandardTypedData(bytes: data)])
    }

    private func emitNeighbor() {
        events?(["type": "neighbor"])
    }
}
