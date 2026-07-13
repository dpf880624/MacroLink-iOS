import Foundation

struct MacroAction: Identifiable, Codable {
    var id: String = UUID().uuidString
    var type: MacroActionType
    var keyCode: Int? = nil
    var keyName: String? = nil
    var modifiers: [String]? = nil
    var x: Int? = nil
    var y: Int? = nil
    var mouseButton: String? = nil
    var scrollDelta: Int? = nil
    var delay: Int = 50
    var action: Int? = nil

    var displayText: String {
        switch type {
        case .keyboard:
            var parts: [String] = []
            if let mods = modifiers, !mods.isEmpty {
                parts.append(mods.map { $0.uppercased() }.joined(separator: "+"))
            }
            parts.append(keyName ?? "Key(\(keyCode ?? 0))")
            return parts.joined(separator: "+")
        case .mouseClick:
            return "\(mouseButton?.capitalized ?? "Left") Click (\(x ?? 0), \(y ?? 0))"
        case .mouseScroll:
            let dir = (scrollDelta ?? 0) > 0 ? "↑" : "↓"
            return "Scroll \(dir) \(abs(scrollDelta ?? 0))"
        case .mouseMove:
            return "Move (\(x ?? 0), \(y ?? 0))"
        case .delay:
            return "Delay \(delay)ms"
        }
    }
}

enum MacroActionType: String, Codable, CaseIterable {
    case keyboard = "keyboard"
    case mouseClick = "mouse_click"
    case mouseScroll = "mouse_scroll"
    case mouseMove = "mouse_move"
    case delay = "delay"

    var displayName: String {
        switch self {
        case .keyboard: return "键盘"
        case .mouseClick: return "鼠标点击"
        case .mouseScroll: return "滚轮"
        case .mouseMove: return "鼠标移动"
        case .delay: return "延时"
        }
    }

    var icon: String {
        switch self {
        case .keyboard: return "keyboard"
        case .mouseClick: return "cursorarrow.click"
        case .mouseScroll: return "scroll"
        case .mouseMove: return "cursorarrow.motion"
        case .delay: return "clock"
        }
    }
}

struct Macro: Identifiable, Codable {
    var id: String = UUID().uuidString
    var name: String
    var description: String = ""
    var actions: [MacroAction] = []
    var loopCount: Int = 1
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var isFavorite: Bool = false

    var totalDuration: Int {
        return actions.reduce(0) { $0 + $1.delay }
    }

    var actionCount: Int {
        return actions.count
    }
}