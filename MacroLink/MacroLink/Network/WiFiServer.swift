import Foundation
import Network

class WiFiServer {
    static let shared = WiFiServer()

    private var listener: NWListener?
    private var clientConnection: NWConnection?
    private var receiveBuffer = Data()
    private let maxBufferSize = Constants.maxReceiveBuffer

    private(set) var isRunning = false
    private(set) var isClientConnected = false
    private(set) var serverPort: UInt16 = Constants.defaultDataPort

    var onClientConnected: (() -> Void)?
    var onClientDisconnected: (() -> Void)?
    var onDataReceived: ((Data) -> Void)?
    var onServerError: ((String) -> Void)?

    private var pingTimer: Timer?
    private let pingInterval = Constants.pingInterval

    private init() {}

    // MARK: - Server Lifecycle

    func start(port: UInt16 = Constants.defaultDataPort) {
        guard !isRunning else { return }

        let params = NWParameters.tcp
        params.allowLocalEndpointReuse = true

        guard let nwPort = NWEndpoint.Port(rawValue: port) else {
            onServerError?("Invalid port: \(port)")
            return
        }

        do {
            listener = try NWListener(using: params, on: nwPort)
        } catch {
            onServerError?("Failed to create listener: \(error.localizedDescription)")
            return
        }

        serverPort = port

        listener?.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                self?.isRunning = true
                print("WiFi Server started on port \(port)")
            case .failed(let error):
                self?.isRunning = false
                self?.onServerError?("Listener failed: \(error.localizedDescription)")
            default:
                break
            }
        }

        listener?.newConnectionHandler = { [weak self] connection in
            self?.handleNewConnection(connection)
        }

        listener?.start(queue: .global())
    }

    func stop() {
        clientConnection?.cancel()
        clientConnection = nil
        isClientConnected = false

        listener?.cancel()
        listener = nil
        isRunning = false

        stopPingTimer()
        receiveBuffer.removeAll()

        print("WiFi Server stopped")
    }

    // MARK: - Client Connection Handling

    private func handleNewConnection(_ connection: NWConnection) {
        if isClientConnected {
            clientConnection?.cancel()
            isClientConnected = false
            onClientDisconnected?()
        }

        clientConnection = connection

        connection.stateUpdateHandler = { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .ready:
                self.isClientConnected = true
                self.onClientConnected?()
                self.startPingTimer()
                self.receiveFromClient()
                print("PC client connected: \(connection.endpoint)")
            case .failed(let error):
                self.handleClientDisconnect()
                self.onServerError?("Client connection failed: \(error.localizedDescription)")
            case .cancelled:
                self.handleClientDisconnect()
            default:
                break
            }
        }

        connection.start(queue: .global())
    }

    private func handleClientDisconnect() {
        guard isClientConnected else { return }
        isClientConnected = false
        clientConnection = nil
        stopPingTimer()
        receiveBuffer.removeAll()
        onClientDisconnected?()
        print("PC client disconnected")
    }

    // MARK: - Send Data

    func send(data: Data) {
        guard let clientConnection = clientConnection, isClientConnected else { return }
        clientConnection.send(content: data, completion: .contentProcessed { [weak self] error in
            if let error = error {
                print("WiFi Server send error: \(error.localizedDescription)")
                self?.handleClientDisconnect()
            }
        })
    }

    func send(command: Command) {
        do {
            let jsonData = try JSONEncoder().encode(command)
            send(data: jsonData)
        } catch {
            print("Failed to encode command: \(error)")
        }
    }

    // MARK: - Receive Data

    private func receiveFromClient() {
        clientConnection?.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, context, isComplete, error in
            guard let self = self else { return }

            if let data = data, !data.isEmpty {
                self.processReceivedData(data)
            }

            if let error = error {
                print("WiFi Server receive error: \(error.localizedDescription)")
                self.handleClientDisconnect()
                return
            }

            if isComplete {
                self.handleClientDisconnect()
                return
            }

            if self.isClientConnected {
                self.receiveFromClient()
            }
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

    // MARK: - Local IP

    func getLocalIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?

        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return nil }

        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family

            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                if name == "en0" {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(NI_MAXHOST),
                                nil, 0, NI_NUMERICHOST)
                    address = String(cString: hostname)
                    break
                }
            }
        }

        freeifaddrs(ifaddr)
        return address
    }
}