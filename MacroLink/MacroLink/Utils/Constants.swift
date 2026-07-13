import Foundation

struct Constants {
    static let defaultDataPort: UInt16 = 8888
    static let defaultDiscoveryPort: UInt16 = 8889
    static let discoveryMessage = "PHONE_REMOTE_KEYBOARD_DISCOVERY"
    static let serverResponsePrefix = "PHONE_REMOTE_KEYBOARD_SERVER"
    static let pingInterval: TimeInterval = 5.0
    static let defaultPressDuration: Int = 50
    static let maxReceiveBuffer: Int = 1024 * 1024
    static let macroSendActionDelay: Int = 20

    struct KeyCode {
        static let backspace = 8
        static let tab = 9
        static let enter = 13
        static let shift = 16
        static let ctrl = 17
        static let alt = 18
        static let capsLock = 20
        static let escape = 27
        static let space = 32
        static let leftWin = 91
        static let rightWin = 92
        static let contextMenu = 93
        static let f1 = 112
        static let f12 = 123
    }
}