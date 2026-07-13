import Foundation

class WiFiServer: NSObject {
    static let shared = WiFiServer()

    private var serverSocket: Int32 = -1
    private var clientSocket: Int32 = -1
    private var receiveBuffer = Data()
    private let maxBufferSize = Constants.maxReceiveBuffer
    private var isListening = false

    private(set) var isRunning = false
    private(set) var isClientConnected = false
    private(set) var serverPort: UInt16 = Constants.defaultDataPort

    var onClientConnected: (() -> Void)?
    var onClientDisconnected: (() -> Void)?
    var onDataReceived: ((Data) -> Void)?
    var onServerError: ((String) -> Void)?

    private var pingTimer: Timer?
    private let pingInterval = Constants.pingInterval

    private override init() {
        super.init()
    }

    func start(port: UInt16 = Constants.defaultDataPort) {
        guard !isRunning else { return }
        serverPort = port

        serverSocket = Darwin.socket(AF_INET, SOCK_STREAM, 0)
        guard serverSocket >= 0 else {
            onServerError?("Failed to create socket")
            return
        }

        var reuse: Int32 = 1
        setsockopt(serverSocket, SOL_SOCKET, SO_REUSEADDR, &reuse, socklen_t(MemoryLayout.size(ofValue: reuse)))

        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = in_port_t(port).bigEndian
        addr.sin_addr.s_addr = INADDR_ANY.bigEndian

        let bindResult = Darwin.bind(serverSocket, sockaddr_cast(&addr), socklen_t(MemoryLayout.size(ofValue: addr)))
        guard bindResult >= 0 else {
            onServerError?("Bind failed")
            close(serverSocket)
            serverSocket = -1
            return
        }

        let listenResult = Darwin.listen(serverSocket, 1)
        guard listenResult >= 0 else {
            onServerError?("Listen failed")
            close(serverSocket)
            serverSocket = -1
            return
        }

        isRunning = true
        isListening = true

        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.acceptLoop()
        }
    }

    private func acceptLoop() {
        while isListening {
            var clientAddr = sockaddr_in()
            var clientAddrLen = socklen_t(MemoryLayout.size(ofValue: clientAddr))
            let newClient = Darwin.accept(serverSocket, sockaddr_cast(&clientAddr), &clientAddrLen)

            guard newClient >= 0 else { continue }

            if clientSocket >= 0 {
                close(clientSocket)
                isClientConnected = false
                DispatchQueue.main.async { self.onClientDisconnected?() }
            }

            clientSocket = newClient
            isClientConnected = true

            DispatchQueue.main.async { [weak self] in
                self?.onClientConnected?()
                self?.startPingTimer()
            }

            receiveLoop()
        }
    }

    private func receiveLoop() {
        var buffer = [UInt8](repeating: 0, count: 65536)
        while isClientConnected {
                let bytesRead = Darwin.recv(clientSocket, &buffer, buffer.count, 0)
            if bytesRead > 0 {
                let data = Data(bytes: buffer, count: bytesRead)
                processReceivedData(data)
            } else {
                handleClientDisconnect()
                break
            }
        }
    }

    func stop() {
        isListening = false
        isRunning = false

        if clientSocket >= 0 {
            close(clientSocket)
            clientSocket = -1
        }
        if serverSocket >= 0 {
            close(serverSocket)
            serverSocket = -1
        }

        isClientConnected = false
        stopPingTimer()
        receiveBuffer.removeAll()
    }

    func send(data: Data) {
        guard clientSocket >= 0, isClientConnected else { return }
        data.withUnsafeBytes { ptr in
            Darwin.send(clientSocket, ptr.baseAddress, data.count, 0)
        }
    }

    func send(command: Command) {
        do {
            let jsonData = try JSONEncoder().encode(command)
            send(data: jsonData)
        } catch {
            print("Failed to encode command: \(error)")
        }
    }

    private func handleClientDisconnect() {
        guard isClientConnected else { return }
        isClientConnected = false
        if clientSocket >= 0 {
            close(clientSocket)
            clientSocket = -1
        }
        stopPingTimer()
        receiveBuffer.removeAll()
        DispatchQueue.main.async { self.onClientDisconnected?() }
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

    private func sockaddr_cast(_ ptr: UnsafeMutablePointer<sockaddr_in>) -> UnsafeMutablePointer<sockaddr> {
        return UnsafeMutableRawPointer(ptr).bindMemory(to: sockaddr.self, capacity: 1)
    }
}
