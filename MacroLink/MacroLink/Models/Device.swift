import Foundation

struct Device: Identifiable, Codable {
    var id: String
    var name: String
    var ipAddress: String
    var port: Int
    var connectionType: ConnectionType
    var isOnline: Bool = true
    var lastSeen: Date = Date()

    var displayName: String {
        return "\(name) (\(ipAddress))"
    }
}

enum ConnectionType: String, Codable, CaseIterable {
    case wifi = "Wi-Fi"
    case bluetooth = "蓝牙"
    case usb = "USB"

    var icon: String {
        switch self {
        case .wifi: return "wifi"
        case .bluetooth: return "bluetooth"
        case .usb: return "cable.connector"
        }
    }
}

enum ConnectionState {
    case disconnected
    case scanning
    case connecting
    case connected
    case error(String)

    var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }

    var displayText: String {
        switch self {
        case .disconnected: return "未连接"
        case .scanning: return "扫描中..."
        case .connecting: return "连接中..."
        case .connected: return "已连接"
        case .error(let msg): return "错误: \(msg)"
        }
    }
}