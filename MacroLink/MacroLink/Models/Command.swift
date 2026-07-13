import Foundation

enum CommandType: String, Codable {
    case keyboard
    case mouse
    case media
    case knob
    case macro
    case keycapture
    case macrorecord
    case ping
    case keycaptureResult = "keycapture_result"
    case macrorecordResult = "macrorecord_result"
    case pcStatus = "pc_status"
    case windowChange = "window_change"
}

enum KeyboardAction: String, Codable {
    case press
    case release
    case type
    case keydown
    case keyup
}

enum MouseAction: String, Codable {
    case move
    case click
    case scroll
    case dragStart = "drag_start"
    case dragEnd = "drag_end"
    case mousedown
    case mouseup
}

enum MouseButton: String, Codable {
    case left
    case right
    case middle
}

enum MediaAction: String, Codable {
    case play
    case pause
    case stop
    case next
    case previous
    case volume
    case brightnessUp = "brightness_up"
    case brightnessDown = "brightness_down"
}

enum KnobAction: String, Codable {
    case rotate
    case click
}

enum KnobDirection: String, Codable {
    case clockwise
    case counterclockwise
}

struct KeyboardPayload: Codable {
    var action: KeyboardAction
    var keyCode: Int? = nil
    var modifiers: [String]? = nil
    var text: String? = nil
    var pressDuration: Int? = nil
}

struct MousePayload: Codable {
    var action: MouseAction
    var x: Int? = nil
    var y: Int? = nil
    var relative: Bool? = true
    var button: MouseButton? = nil
    var delta: Int? = nil
    var modifiers: [String]? = nil
}

struct MediaPayload: Codable {
    var action: MediaAction
    var volume: Int? = nil
}

struct KnobPayload: Codable {
    var action: KnobAction
    var direction: KnobDirection? = nil
    var steps: Int? = nil
    var binding: String? = nil
}

struct MacroPayload: Codable {
    var marker: String? = nil
    var name: String? = nil
    var actionCount: Int? = nil
    var loopCount: Int? = nil
    var executedLoops: Int? = nil
    var cancelled: Bool? = nil
    var error: Bool? = nil
    var action: String? = nil
    var macroId: String? = nil
    var macroName: String? = nil
    var macroDescription: String? = nil
    var totalActions: Int? = nil
    var index: Int? = nil
    var delay: Int? = nil
    var command: MacroActionCommand? = nil
}

struct MacroActionCommand: Codable {
    var id: String? = nil
    var type: String? = nil
    var timestamp: Int64? = nil
    var payload: [String: AnyCodable]? = nil
}

struct KeyCapturePayload: Codable {
    var action: String
}

struct MacroRecordPayload: Codable {
    var action: String
    var useFixedDelay: Bool? = nil
    var fixedDelayMs: Int? = nil
    var recordMouseClick: Bool? = nil
    var recordMouseAll: Bool? = nil
    var recordKeyboard: Bool? = nil
}

struct Command: Codable {
    var id: String
    var type: CommandType
    var timestamp: Int64
    var payload: AnyCodable

    init(id: String = UUID().uuidString, type: CommandType, timestamp: Int64 = Int64(Date().timeIntervalSince1970 * 1000), payload: AnyCodable) {
        self.id = id
        self.type = type
        self.timestamp = timestamp
        self.payload = payload
    }

    static func keyboard(action: KeyboardAction, keyCode: Int? = nil, modifiers: [String]? = nil, text: String? = nil, pressDuration: Int? = nil) -> Command {
        let payload = KeyboardPayload(action: action, keyCode: keyCode, modifiers: modifiers, text: text, pressDuration: pressDuration)
        return Command(type: .keyboard, payload: AnyCodable(payload))
    }

    static func mouse(action: MouseAction, x: Int? = nil, y: Int? = nil, relative: Bool = true, button: MouseButton? = nil, delta: Int? = nil, modifiers: [String]? = nil) -> Command {
        let payload = MousePayload(action: action, x: x, y: y, relative: relative, button: button, delta: delta, modifiers: modifiers)
        return Command(type: .mouse, payload: AnyCodable(payload))
    }

    static func media(action: MediaAction, volume: Int? = nil) -> Command {
        let payload = MediaPayload(action: action, volume: volume)
        return Command(type: .media, payload: AnyCodable(payload))
    }

    static func knob(action: KnobAction, direction: KnobDirection? = nil, steps: Int? = nil, binding: String? = nil) -> Command {
        let payload = KnobPayload(action: action, direction: direction, steps: steps, binding: binding)
        return Command(type: .knob, payload: AnyCodable(payload))
    }

    static func ping() -> Command {
        return Command(id: "ping", type: .ping, timestamp: 0, payload: AnyCodable([String: String]()))
    }
}

struct AnyCodable: Codable, Equatable {
    var value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case is NSNull: try container.encodeNil()
        case let bool as Bool: try container.encode(bool)
        case let int as Int: try container.encode(int)
        case let double as Double: try container.encode(double)
        case let string as String: try container.encode(string)
        case let array as [Any]:
            let codableArray = array.map { AnyCodable($0) }
            try container.encode(codableArray)
        case let dict as [String: Any]:
            let codableDict = dict.mapValues { AnyCodable($0) }
            try container.encode(codableDict)
        default: try container.encodeNil()
        }
    }

    static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        return String(describing: lhs.value) == String(describing: rhs.value)
    }
}