import Foundation
import Combine

class MacroViewModel: ObservableObject {
    private let connectionManager = ConnectionManager.shared

    @Published var macros: [Macro] = []
    @Published var isRecording: Bool = false
    @Published var isPlaying: Bool = false
    @Published var currentPlayingMacro: Macro? = nil
    @Published var executedLoops: Int = 0

    private var playCancellable: AnyCancellable? = nil

    init() {
        loadMacros()
    }

    // MARK: - CRUD

    func addMacro(_ macro: Macro) {
        macros.append(macro)
        saveMacros()
    }

    func updateMacro(_ macro: Macro) {
        if let index = macros.firstIndex(where: { $0.id == macro.id }) {
            var updated = macro
            updated.updatedAt = Date()
            macros[index] = updated
            saveMacros()
        }
    }

    func deleteMacro(_ macro: Macro) {
        macros.removeAll { $0.id == macro.id }
        saveMacros()
    }

    func toggleFavorite(_ macro: Macro) {
        if let index = macros.firstIndex(where: { $0.id == macro.id }) {
            macros[index].isFavorite.toggle()
            saveMacros()
        }
    }

    // MARK: - Play Macro

    func playMacro(_ macro: Macro) {
        guard connectionManager.connectionState.isConnected else { return }
        guard !isPlaying else { return }

        isPlaying = true
        currentPlayingMacro = macro
        executedLoops = 0

        sendMacroMarker("start", name: macro.name, actionCount: macro.actionCount, loopCount: macro.loopCount)

        var currentLoop = 0
        var actionIndex = 0

        func playNextAction() {
            guard currentLoop < macro.loopCount && isPlaying else {
                sendMacroMarker("end", name: macro.name, actionCount: macro.actionCount, loopCount: macro.loopCount, executedLoops: currentLoop)
                isPlaying = false
                currentPlayingMacro = nil
                return
            }

            let action = macro.actions[actionIndex]
            sendMacroAction(action)

            actionIndex += 1
            if actionIndex >= macro.actions.count {
                actionIndex = 0
                currentLoop += 1
                executedLoops = currentLoop
            }

            let delayMs = max(action.delay, 10)
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(delayMs)) {
                playNextAction()
            }
        }

        playNextAction()
    }

    func stopPlaying() {
        isPlaying = false
        if let macro = currentPlayingMacro {
            sendMacroMarker("end", name: macro.name, actionCount: macro.actionCount, loopCount: macro.loopCount, executedLoops: executedLoops, cancelled: true)
        }
        currentPlayingMacro = nil
    }

    private func sendMacroAction(_ action: MacroAction) {
        switch action.type {
        case .keyboard:
            if let keyCode = action.keyCode {
                let command = Command.keyboard(
                    action: .press,
                    keyCode: keyCode,
                    modifiers: action.modifiers
                )
                connectionManager.sendCommand(command)
            }
        case .mouseClick:
            let button: MouseButton = action.mouseButton == "right" ? .right : (action.mouseButton == "middle" ? .middle : .left)
            let command = Command.mouse(action: .click, x: action.x, y: action.y, relative: false, button: button)
            connectionManager.sendCommand(command)
        case .mouseScroll:
            let command = Command.mouse(action: .scroll, delta: action.scrollDelta)
            connectionManager.sendCommand(command)
        case .mouseMove:
            let command = Command.mouse(action: .move, x: action.x, y: action.y, relative: false)
            connectionManager.sendCommand(command)
        case .delay:
            break
        }
    }

    private func sendMacroMarker(_ marker: String, name: String, actionCount: Int, loopCount: Int, executedLoops: Int = 0, cancelled: Bool = false) {
        let payload = MacroPayload(
            marker: marker,
            name: name,
            actionCount: actionCount,
            loopCount: loopCount,
            executedLoops: executedLoops,
            cancelled: cancelled
        )
        let command = Command(type: .macro, payload: AnyCodable(payload))
        connectionManager.sendCommand(command)
    }

    // MARK: - Recording

    func startRecording() {
        guard connectionManager.connectionState.isConnected else { return }
        isRecording = true
        let payload = MacroRecordPayload(action: "start", useFixedDelay: false, fixedDelayMs: 10, recordMouseClick: true, recordMouseAll: true, recordKeyboard: true)
        let command = Command(type: .macrorecord, payload: AnyCodable(payload))
        connectionManager.sendCommand(command)
    }

    func stopRecording() {
        isRecording = false
        let payload = MacroRecordPayload(action: "stop")
        let command = Command(type: .macrorecord, payload: AnyCodable(payload))
        connectionManager.sendCommand(command)
    }

    // MARK: - Persistence

    private func saveMacros() {
        do {
            let data = try JSONEncoder().encode(macros)
            UserDefaults.standard.set(data, forKey: "saved_macros")
        } catch {
            print("Failed to save macros: \(error)")
        }
    }

    private func loadMacros() {
        guard let data = UserDefaults.standard.data(forKey: "saved_macros") else { return }
        do {
            macros = try JSONDecoder().decode([Macro].self, from: data)
        } catch {
            print("Failed to load macros: \(error)")
        }
    }
}

extension DispatchQueue {
    func asyncAfter(deadline: DispatchTime, qos: DispatchQoS = .unspecified, execute work: @escaping () -> Void) {
        asyncAfter(deadline: deadline, qos: qos, flags: [], execute: work)
    }
}