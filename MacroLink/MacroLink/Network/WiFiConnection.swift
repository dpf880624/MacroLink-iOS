import Foundation

class WiFiConnection: NSObject {
    static let shared = WiFiConnection()

    private var tcpSocket: Int32 = -1
    private var udpSocket: Int32 = -1
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
    private var isConnected = false

    private override init() {
        super.init()
    }

    func startDiscovery() {
        udpSocket = Darwin.socket(AF_INET, SOCK_DGRAM, 0)
        guard udpSocket >= 0 else { return }

        var broadcast: Int32 = 1
        setsockopt(udpSocket, SOL_SOCKET, SO_BROADCAST, &broadcast, socklen_t(MemoryLayout.size(ofValue: broadcast)))

        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = in_port_t(discoveryPort).bigEndian
        addr.sin_addr.s_addr = INADDR_ANY.bigEndian

        if Darwin.bind(udpSocket, sockaddr_cast(&addr), socklen_t(MemoryLayout.size(ofValue: addr))) < 0 {
            close(udpSocket)
            udpSocket = -1
            return
        }

        sendDiscoveryBroadcast()

        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.listenForDiscoveryResponse()
        }
    }

    func stopDiscovery() {
        if udpSocket >= 0 {
            close(udpSocket)
            udpSocket = -1
        }
    }

    private func sendDiscoveryBroadcast() {
        guard udpSocket >= 0 else { return }
        let data = discoveryMessage.data(using: .utf8)!

        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = in_port_t(discoveryPort).bigEndian
        addr.sin_addr.s_addr = in_addr_t(0xFFFFFFFF)

        data.withUnsafeBytes { ptr in
            Darwin.sendto(udpSocket, ptr.baseAddress, data.count, 0, sockaddr_cast(&addr), socklen_t(MemoryLayout.size(ofValue: addr)))
        }
    }

    private func listenForDiscoveryResponse() {
        var buffer = [UInt8](repeating: 0, count: 1024)
        while udpSocket >= 0 {
            var senderAddr = sockaddr_in()
            var senderAddrLen = socklen_t(MemoryLayout.size(ofValue: senderAddr))
            let bytesRead = Darwin.recvfrom(udpSocket, &buffer, buffer.count, 0, sockaddr_cast(&senderAddr), &senderAddrLen)

            if bytesRead > 0 {
                let response = String(bytes: buffer[0..<bytesRead], encoding: .utf8) ?? ""
                parseDiscoveryResponse(response)
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

        let device = Device(id: "\(ip):\(port)", name: hostname, ipAddress: ip, port: port, connectionType: .wifi)
        DispatchQueue.main.async { self.onDeviceDiscovered?(device) }
    }

    func connect(to device: Device) {
        DispatchQueue.main.async { self.onConnectionStateChanged?(.connecting) }

        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }

            self.tcpSocket = Darwin.socket(AF_INET, SOCK_STREAM, 0)
            guard self.tcpSocket >= 0 else {
                DispatchQueue.main.async { self.onConnectionStateChanged?(.error("Socket creation failed")) }
                return
            }

            var addr = sockaddr_in()
            addr.sin_family = sa_family_t(AF_INET)
            addr.sin_port = in_port_t(UInt16(device.port)).bigEndian
            inet_pton(AF_INET, device.ipAddress, &addr.sin_addr)

            let result = Darwin.connect(self.tcpSocket, self.sockaddr_cast(&addr), socklen_t(MemoryLayout.size(ofValue: addr)))
            if result >= 0 {
                self.isConnected = true
                DispatchQueue.main.async {
                    self.onConnectionStateChanged?(.connected)
                    self.startPingTimer()
                }
                self.receiveLoop()
            } else {
                close(self.tcpSocket)
                self.tcpSocket = -1
                DispatchQueue.main.async { self.onConnectionStateChanged?(.error("Connection failed")) }
            }
        }
    }

    func disconnect() {
        stopPingTimer()
        isConnected = false
        if tcpSocket >= 0 {
            close(tcpSocket)
            tcpSocket = -1
        }
        receiveBuffer.removeAll()
        onConnectionStateChanged?(.disconnected)
    }

    func send(command: Command) {
        do {
            let jsonData = try JSONEncoder().encode(command)
            sendRaw(data: jsonData)
        } catch {
            print("Failed to encode command: \(error)")
        }
    }

    func sendRaw(data: Data) {
        guard tcpSocket >= 0 else { return }
        data.withUnsafeBytes { ptr in
            Darwin.send(tcpSocket, ptr.baseAddress, data.count, 0)
        }
    }

    private func receiveLoop() {
        var buffer = [UInt8](repeating: 0, count: 65536)
        while isConnected {
            let bytesRead = Darwin.recv(tcpSocket, &buffer, buffer.count, 0)
            if bytesRead > 0 {
                let data = Data(bytes: buffer, count: bytesRead)
                processReceivedData(data)
            } else {
                isConnected = false
                DispatchQueue.main.async { self.onConnectionStateChanged?(.disconnected) }
                break
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
            DispatchQueue.main.async { self.onDataReceived?(jsonData) }
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
            if escape { escape = false; continue }
            if byte == UInt8(ascii: "\\") && inString { escape = true; continue }
            if byte == UInt8(ascii: "\"") { inString = !inString; continue }
            if inString { continue }
            if byte == UInt8(ascii: "{") { if depth == 0 { startIndex = i }; depth += 1 }
            else if byte == UInt8(ascii: "}") { depth -= 1; if depth == 0, let start = startIndex { return i + 1 } }
        }
        return nil
    }

    private func startPingTimer() {
        stopPingTimer()
        DispatchQueue.main.async { [weak self] in
            self?.pingTimer = Timer.scheduledTimer(withTimeInterval: self?.pingInterval ?? 5.0, repeats: true) { [weak self] _ in
                self?.send(command: .ping())
            }
        }
    }

    private func stopPingTimer() {
        DispatchQueue.main.async { [weak self] in
            self?.pingTimer?.invalidate()
            self?.pingTimer = nil
        }
    }

    private func sockaddr_cast(_ ptr: UnsafeMutablePointer<sockaddr_in>) -> UnsafeMutablePointer<sockaddr> {
        return UnsafeMutableRawPointer(ptr).bindMemory(to: sockaddr.self, capacity: 1)
    }
}
