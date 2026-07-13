import Foundation
import Combine

class ConnectionManager: ObservableObject {
    static let shared = ConnectionManager()

    @Published var connectionState: ConnectionState = .disconnected
    @Published var connectedDevice: Device? = nil
    @Published var discoveredDevices: [Device] = []

    @Published var wifiServerRunning: Bool = false
    @Published var wifiServerClientConnected: Bool = false
    @Published var wifiServerIP: String? = nil

    private let wifiConnection = WiFiConnection.shared
    private let wifiServer = WiFiServer.shared
    private var cancellables = Set<AnyCancellable>()

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
            }
        }

        wifiConnection.onConnectionStateChanged = { [weak self] state in
            DispatchQueue.main.async {
                self?.connectionState = state
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
            }
        }

        wifiServer.onClientDisconnected = { [weak self] in
            DispatchQueue.main.async {
                self?.wifiServerClientConnected = false
                if self?.wifiServerRunning == true {
                    self?.connectionState = .disconnected
                }
            }
        }

        wifiServer.onDataReceived = { [weak self] data in
            self?.handleReceivedData(data)
        }

        wifiServer.onServerError = { [weak self] errorMsg in
            DispatchQueue.main.async {
                self?.connectionState = .error(errorMsg)
            }
        }
    }

    // MARK: - Public API (Client Mode)

    func startScan() {
        discoveredDevices.removeAll()
        connectionState = .scanning
        wifiConnection.startDiscovery()
    }

    func stopScan() {
        wifiConnection.stopDiscovery()
        if !connectionState.isConnected {
            connectionState = .disconnected
        }
    }

    func connect(to device: Device) {
        connectedDevice = device
        wifiConnection.connect(to: device)
    }

    func disconnect() {
        wifiConnection.disconnect()
        connectedDevice = nil
        connectionState = .disconnected
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

    // MARK: - Public API (Server Mode)

    func startWiFiServer(port: UInt16 = Constants.defaultDataPort) {
        wifiServer.start(port: port)
        wifiServerRunning = true
        wifiServerIP = wifiServer.getLocalIPAddress()
        connectionState = .disconnected
    }

    func stopWiFiServer() {
        wifiServer.stop()
        wifiServerRunning = false
        wifiServerClientConnected = false
        wifiServerIP = nil
        connectionState = .disconnected
    }

    // MARK: - Data Handling

    private func handleReceivedData(_ data: Data) {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else { return }

        switch type {
        case "pc_status":
            handlePCStatus(json)
        case "window_change":
            handleWindowChange(json)
        case "keycapture_result":
            handleKeyCaptureResult(json)
        case "macrorecord_result":
            handleMacroRecordResult(json)
        default:
            break
        }
    }

    private func handlePCStatus(_ json: [String: Any]) {
        NotificationCenter.default.post(name: .pcStatusUpdate, object: nil, userInfo: json)
    }

    private func handleWindowChange(_ json: [String: Any]) {
        NotificationCenter.default.post(name: .windowChange, object: nil, userInfo: json)
    }

    private func handleKeyCaptureResult(_ json: [String: Any]) {
        NotificationCenter.default.post(name: .keyCaptureResult, object: nil, userInfo: json)
    }

    private func handleMacroRecordResult(_ json: [String: Any]) {
        NotificationCenter.default.post(name: .macroRecordResult, object: nil, userInfo: json)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let pcStatusUpdate = Notification.Name("pcStatusUpdate")
    static let windowChange = Notification.Name("windowChange")
    static let keyCaptureResult = Notification.Name("keyCaptureResult")
    static let macroRecordResult = Notification.Name("macroRecordResult")
}