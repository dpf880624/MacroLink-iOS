import Foundation

class ConnectionManager {
    static let shared = ConnectionManager()

    var connectionState: ConnectionState = .disconnected
    var connectedDevice: Device? = nil
    var discoveredDevices: [Device] = []

    var wifiServerRunning: Bool = false
    var wifiServerClientConnected: Bool = false
    var wifiServerIP: String? = nil

    private let wifiConnection = WiFiConnection.shared
    private let wifiServer = WiFiServer.shared

    private init() {
        setupCallbacks()
        setupServerCallbacks()
    }

    private func setupCallbacks() {
        wifiConnection.onDeviceDiscovered = { [weak self] device in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if !self.discoveredDevices.contains(where: { $0.id == device.id }) {
                    self.discoveredDevices.append(device)
                }
                self.notifyStateChanged()
            }
        }

        wifiConnection.onConnectionStateChanged = { [weak self] state in
            DispatchQueue.main.async {
                self?.connectionState = state
                self?.notifyStateChanged()
            }
        }

        wifiConnection.onDataReceived = { [weak self] data in
            self?.handleReceivedData(data)
        }
    }

    private func setupServerCallbacks() {
        wifiServer.onClientConnected = { [weak self] in
            DispatchQueue.main.async {
                self?.wifiServerClientConnected = true
                self?.connectionState = .connected
                self?.wifiServerIP = self?.wifiServer.getLocalIPAddress()
                self?.notifyStateChanged()
            }
        }

        wifiServer.onClientDisconnected = { [weak self] in
            DispatchQueue.main.async {
                self?.wifiServerClientConnected = false
                if self?.wifiServerRunning == true {
                    self?.connectionState = .disconnected
                }
                self?.notifyStateChanged()
            }
        }

        wifiServer.onDataReceived = { [weak self] data in
            self?.handleReceivedData(data)
        }

        wifiServer.onServerError = { [weak self] errorMsg in
            DispatchQueue.main.async {
                self?.connectionState = .error(errorMsg)
                self?.notifyStateChanged()
            }
        }
    }

    private func notifyStateChanged() {
        NotificationCenter.default.post(name: Notification.Name("ConnectionStateChanged"), object: nil)
    }

    func startScan() {
        discoveredDevices.removeAll()
        connectionState = .scanning
        notifyStateChanged()
        wifiConnection.startDiscovery()
    }

    func stopScan() {
        wifiConnection.stopDiscovery()
        if !connectionState.isConnected {
            connectionState = .disconnected
        }
        notifyStateChanged()
    }

    func connect(to device: Device) {
        connectedDevice = device
        wifiConnection.connect(to: device)
    }

    func disconnect() {
        wifiConnection.disconnect()
        connectedDevice = nil
        connectionState = .disconnected
        notifyStateChanged()
    }

    func sendCommand(_ command: Command) {
        if wifiServerClientConnected {
            wifiServer.send(command: command)
        } else if connectionState.isConnected {
            wifiConnection.send(command: command)
        }
    }

    func sendRawData(_ data: Data) {
        if wifiServerClientConnected {
            wifiServer.send(data: data)
        } else if connectionState.isConnected {
            wifiConnection.sendRaw(data: data)
        }
    }

    func startWiFiServer(port: UInt16 = Constants.defaultDataPort) {
        wifiServer.start(port: port)
        wifiServerRunning = true
        wifiServerIP = wifiServer.getLocalIPAddress()
        connectionState = .disconnected
        notifyStateChanged()
    }

    func stopWiFiServer() {
        wifiServer.stop()
        wifiServerRunning = false
        wifiServerClientConnected = false
        wifiServerIP = nil
        connectionState = .disconnected
        notifyStateChanged()
    }

    private func handleReceivedData(_ data: Data) {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else { return }

        switch type {
        case "pc_status":
            NotificationCenter.default.post(name: .pcStatusUpdate, object: nil, userInfo: json)
        case "window_change":
            NotificationCenter.default.post(name: .windowChange, object: nil, userInfo: json)
        case "keycapture_result":
            NotificationCenter.default.post(name: .keyCaptureResult, object: nil, userInfo: json)
        case "macrorecord_result":
            NotificationCenter.default.post(name: .macroRecordResult, object: nil, userInfo: json)
        default:
            break
        }
    }
}

extension Notification.Name {
    static let pcStatusUpdate = Notification.Name("pcStatusUpdate")
    static let windowChange = Notification.Name("windowChange")
    static let keyCaptureResult = Notification.Name("keyCaptureResult")
    static let macroRecordResult = Notification.Name("macroRecordResult")
}
