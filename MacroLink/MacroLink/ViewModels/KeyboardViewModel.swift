import Foundation
import Combine

class KeyboardViewModel: ObservableObject {
    private let connectionManager = ConnectionManager.shared

    func sendKeyPress(keyCode: Int, modifiers: [String] = []) {
        let command = Command.keyboard(action: .press, keyCode: keyCode, modifiers: modifiers)
        connectionManager.sendCommand(command)
    }

    func sendKeyDown(keyCode: Int, modifiers: [String] = []) {
        let command = Command.keyboard(action: .keydown, keyCode: keyCode, modifiers: modifiers)
        connectionManager.sendCommand(command)
    }

    func sendKeyUp(keyCode: Int, modifiers: [String] = []) {
        let command = Command.keyboard(action: .keyup, keyCode: keyCode, modifiers: modifiers)
        connectionManager.sendCommand(command)
    }

    func sendText(_ text: String) {
        let command = Command.keyboard(action: .type, text: text)
        connectionManager.sendCommand(command)
    }

    func sendMediaAction(_ action: MediaAction) {
        let command = Command.media(action: action)
        connectionManager.sendCommand(command)
    }
}

struct KeyDefinition: Identifiable {
    let id: String
    let label: String
    let keyCode: Int
    let width: CGFloat
    let isModifier: Bool
    let modifierName: String?

    init(label: String, keyCode: Int, width: CGFloat = 1.0, isModifier: Bool = false, modifierName: String? = nil) {
        self.id = "\(keyCode)_\(label)"
        self.label = label
        self.keyCode = keyCode
        self.width = width
        self.isModifier = isModifier
        self.modifierName = modifierName
    }
}

let keyboardRows: [[KeyDefinition]] = [
    [
        KeyDefinition(label: "Esc", keyCode: 27, width: 1.0),
        KeyDefinition(label: "F1", keyCode: 112), KeyDefinition(label: "F2", keyCode: 113),
        KeyDefinition(label: "F3", keyCode: 114), KeyDefinition(label: "F4", keyCode: 115),
        KeyDefinition(label: "F5", keyCode: 116), KeyDefinition(label: "F6", keyCode: 117),
        KeyDefinition(label: "F7", keyCode: 118), KeyDefinition(label: "F8", keyCode: 119),
        KeyDefinition(label: "F9", keyCode: 120), KeyDefinition(label: "F10", keyCode: 121),
        KeyDefinition(label: "F11", keyCode: 122), KeyDefinition(label: "F12", keyCode: 123),
    ],
    [
        KeyDefinition(label: "`", keyCode: 192), KeyDefinition(label: "1", keyCode: 49),
        KeyDefinition(label: "2", keyCode: 50), KeyDefinition(label: "3", keyCode: 51),
        KeyDefinition(label: "4", keyCode: 52), KeyDefinition(label: "5", keyCode: 53),
        KeyDefinition(label: "6", keyCode: 54), KeyDefinition(label: "7", keyCode: 55),
        KeyDefinition(label: "8", keyCode: 56), KeyDefinition(label: "9", keyCode: 57),
        KeyDefinition(label: "0", keyCode: 48), KeyDefinition(label: "-", keyCode: 189),
        KeyDefinition(label: "=", keyCode: 187), KeyDefinition(label: "⌫", keyCode: 8, width: 1.5),
    ],
    [
        KeyDefinition(label: "Tab", keyCode: 9, width: 1.5),
        KeyDefinition(label: "Q", keyCode: 81), KeyDefinition(label: "W", keyCode: 87),
        KeyDefinition(label: "E", keyCode: 69), KeyDefinition(label: "R", keyCode: 82),
        KeyDefinition(label: "T", keyCode: 84), KeyDefinition(label: "Y", keyCode: 89),
        KeyDefinition(label: "U", keyCode: 85), KeyDefinition(label: "I", keyCode: 73),
        KeyDefinition(label: "O", keyCode: 79), KeyDefinition(label: "P", keyCode: 80),
        KeyDefinition(label: "[", keyCode: 219), KeyDefinition(label: "]", keyCode: 221),
        KeyDefinition(label: "\\", keyCode: 220, width: 1.5),
    ],
    [
        KeyDefinition(label: "Caps", keyCode: 20, width: 1.75),
        KeyDefinition(label: "A", keyCode: 65), KeyDefinition(label: "S", keyCode: 83),
        KeyDefinition(label: "D", keyCode: 68), KeyDefinition(label: "F", keyCode: 70),
        KeyDefinition(label: "G", keyCode: 71), KeyDefinition(label: "H", keyCode: 72),
        KeyDefinition(label: "J", keyCode: 74), KeyDefinition(label: "K", keyCode: 75),
        KeyDefinition(label: "L", keyCode: 76), KeyDefinition(label: ";", keyCode: 186),
        KeyDefinition(label: "'", keyCode: 222), KeyDefinition(label: "Enter", keyCode: 13, width: 2.25),
    ],
    [
        KeyDefinition(label: "Shift", keyCode: 16, width: 2.25, isModifier: true, modifierName: "shift"),
        KeyDefinition(label: "Z", keyCode: 90), KeyDefinition(label: "X", keyCode: 88),
        KeyDefinition(label: "C", keyCode: 67), KeyDefinition(label: "V", keyCode: 86),
        KeyDefinition(label: "B", keyCode: 66), KeyDefinition(label: "N", keyCode: 78),
        KeyDefinition(label: "M", keyCode: 77), KeyDefinition(label: ",", keyCode: 188),
        KeyDefinition(label: ".", keyCode: 190), KeyDefinition(label: "/", keyCode: 191),
        KeyDefinition(label: "Shift", keyCode: 16, width: 2.75, isModifier: true, modifierName: "shift"),
    ],
    [
        KeyDefinition(label: "Ctrl", keyCode: 17, width: 1.25, isModifier: true, modifierName: "ctrl"),
        KeyDefinition(label: "Win", keyCode: 91, width: 1.25, isModifier: true, modifierName: "win"),
        KeyDefinition(label: "Alt", keyCode: 18, width: 1.25, isModifier: true, modifierName: "alt"),
        KeyDefinition(label: "Space", keyCode: 32, width: 6.25),
        KeyDefinition(label: "Alt", keyCode: 18, width: 1.25, isModifier: true, modifierName: "alt"),
        KeyDefinition(label: "Win", keyCode: 91, width: 1.25, isModifier: true, modifierName: "win"),
        KeyDefinition(label: "Menu", keyCode: 93, width: 1.25),
        KeyDefinition(label: "Ctrl", keyCode: 17, width: 1.25, isModifier: true, modifierName: "ctrl"),
    ],
]