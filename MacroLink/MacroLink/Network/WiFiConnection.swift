import Foundation
import Network

class WiFiConnection: NSObject {
    static let shared = WiFiConnection()

    private var tcpClient: NWConnection?
    private var udpSocket: NWConnection?
    private var receiveBuffer = Data()
    private let maxBufferSize = 1024 * 1024

    var onDeviceDiscovered: ((Device) -> Void)?
    var onDataReceived: ((Data) -> Void)?
    var onConnectionStateChanged: ((ConnectionState) -> Void)?

    private let discoveryPort: UInt16 = 8889
    private let dataPort: UInt16 = 8888
    private let discoveryMessage = "PHONE_REMOTE_KEYBOARD_DISCOVERY"
    private let serverResponsePrefix = "PHONE_REMOTE_KEYBOARD_SERVER"

    private var pingTimer: Timer?
    private let pingInterval: TimeInterval = 5.0

    private override init() {
        super.init()
    }

    // MARK: - Device Discovery

    func startDiscovery() {
        let endpoint = NWEndpoint.hostPort(host: .ipv4(.broadcast), port: NWEndpoint.Port(rawValue: discoveryPort)!)
        let params = NWParameters.udp
        params.allowLocalEndpointReuse = true
        udpSocket = NWConnection(to: endpoint, using: params)

        udpSocket?.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                self?.sendDiscoveryBroadcast()
                self?.startListeningForDiscoveryResponse()
            case .failed(let error):
                print("UDP discovery failed: \(error)")
            default:
                break
            }
        }
        udpSocket?.start(queue: .global())
    }

    func stopDiscovery() {
        udpSocket?.cancel()
        udpSocket = nil
    }

    private func sendDiscoveryBroadcast() {
        let data = discoveryMessage.data(using: .utf8)!
        udpSocket?.send(content: data, completion: .contentProcessed { error in
            if let error = error {
                print("Discovery broadcast failed: \(error)")
            }
        })
    }

    private func startListeningForDiscoveryResponse() {
        udpSocket?.receiveMessage { [weak self] data, context, isComplete, error in
            guard let self = self else { return }
            if let data = data, let response = String(data: data, encoding: .utf8) {
                self.parseDiscoveryResponse(response)
            }
            if error == nil {
                self.startListeningForDiscoveryResponse()
            }
        }
    }

    private func parseDiscoveryResponse(_ response: String) {
        guard response.hasPrefix(serverResponsePrefix) else { return }
        let parts = response.split(separator: ":")
        guard parts.count >= 4 else { return }

        let ip = String(parts[1])
        guard let port = Int(String(parts[2])) else { return }
        let hostname = parts[3...].joined(separator: ":").trimmingCharacters(in: .whitespaces)

        let device = Device(
            id: "\(ip):\(port)",
            name: hostname,
            ipAddress: ip,
            port: port,
            connectionType: .wifi
        )
        onDeviceDiscovered?(device)
    }

    // MARK: - TCP Connection

    func connect(to device: Device) {
        onConnectionStateChanged?(.connecting)

        let endpoint = NWEndpoint.hostPort(
            host: .init(device.ipAddress),
            port: NWEndpoint.Port(rawValue: UInt16(device.port))!
        )
        let params = NWParameters.tcp
        tcpClient = NWConnection(to: endpoint, using: params)

        tcpClient?.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                self?.onConnectionStateChanged?(.connected)
                self?.startPingTimer()
                self?.receiveData()
            case .failed(let error):
                self?.onConnectionStateChanged?(.error(error.localizedDescription))
                self?.stopPingTimer()
            case .waiting(let error):
                self?.onConnectionStateChanged?(.error(error.localizedDescription))
            default:
                break
            }
        }
        tcpClient?.start(queue: .global())
    }

    func disconnect() {
        stopPingTimer()
        tcpClient?.cancel()
        tcpClient = nil
        receiveBuffer.removeAll()
        onConnectionStateChanged?(.disconnected)
    }

    // MARK: - Send Data

    func send(command: Command) {
        guard let tcpClient = tcpClient else { return }
        do {
            let jsonData = try JSONEncoder().encode(command)
            sendRaw(data: jsonData)
        } catch {
            print("Failed to encode command: \(error)")
        }
    }

    func sendRaw(data: Data) {
        guard let tcpClient = tcpClient else { return }
        tcpClient.send(content: data, completion: .contentProcessed { error in
            if let error = error {
                print("Send failed: \(error)")
            }
        })
    }

    // MARK: - Receive Data

    private func receiveData() {
        tcpClient?.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, context, isComplete, error in
            guard let self = self else { return }

            if let data = data, !data.isEmpty {
                self.processReceivedData(data)
            }

            if let error = error {
                print("Receive error: \(error)")
                return
            }

            if isComplete {
                self.onConnectionStateChanged?(.disconnected)
                return
            }

            self.receiveData()
        }
    }

    private func processReceivedData(_ data: Data) {
        receiveBuffer.append(data)
        if receiveBuffer.count > maxBufferSize {
            receiveBuffer.removeAll()
            return
        }

        while let jsonEndIndex = findCompleteJSON() {
            let jsonData = receiveBuffer.subdata(in: 0..<jsonEndIndex)
            receiveBuffer = receiveBuffer.subdata(in: jsonEndIndex..<receiveBuffer.count)
            onDataReceived?(jsonData)
        }
    }

    private func findCompleteJSON() -> Int? {
        guard !receiveBuffer.isEmpty else { return nil }

        var depth = 0
        var inString = false
        var escape = false
        var startIndex: Int? = nil

        for i in 0..<receiveBuffer.count {
            let byte = receiveBuffer[i]

            if escape {
                escape = false
                continue
            }

            if byte == UInt8(ascii: "\\") && inString {
                escape = true
                continue
            }

            if byte == UInt8(ascii: "\"") {
                inString = !inString
                continue
            }

            if inString { continue }

            if byte == UInt8(ascii: "{") {
                if depth == 0 { startIndex = i }
                depth += 1
            } else if byte == UInt8(ascii: "}") {
                depth -= 1
                if depth == 0, let start = startIndex {
                    return i + 1
                }
            }
        }

        return nil
    }

    // MARK: - Ping

    private func startPingTimer() {
        stopPingTimer()
        pingTimer = Timer.scheduledTimer(withTimeInterval: pingInterval, repeats: true) { [weak self] _ in
            self?.send(command: .ping())
        }
    }

    private func stopPingTimer() {
        pingTimer?.invalidate()
        pingTimer = nil
    }
}