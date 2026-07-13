import Foundation

class TouchpadViewModel {
    private let connectionManager = ConnectionManager.shared

    var sensitivity: Float = 1.0
    var scrollSensitivity: Float = 1.0
    var isLeftButtonDown: Bool = false
    var isRightButtonDown: Bool = false
    var isMiddleButtonDown: Bool = false

    func handleMove(dx: CGFloat, dy: CGFloat) {
        let scaledX = Int(dx * CGFloat(sensitivity))
        let scaledY = Int(dy * CGFloat(sensitivity))
        guard scaledX != 0 || scaledY != 0 else { return }
        let command = Command.mouse(action: .move, x: scaledX, y: scaledY, relative: true)
        connectionManager.sendCommand(command)
    }

    func handleTap() {
        let command = Command.mouse(action: .click, button: .left)
        connectionManager.sendCommand(command)
    }

    func handleRightClick() {
        let command = Command.mouse(action: .click, button: .right)
        connectionManager.sendCommand(command)
    }

    func handleMiddleClick() {
        let command = Command.mouse(action: .click, button: .middle)
        connectionManager.sendCommand(command)
    }

    func handleLeftDown() {
        isLeftButtonDown = true
        let command = Command.mouse(action: .mousedown, button: .left)
        connectionManager.sendCommand(command)
    }

    func handleLeftUp() {
        isLeftButtonDown = false
        let command = Command.mouse(action: .mouseup, button: .left)
        connectionManager.sendCommand(command)
    }

    func handleRightDown() {
        isRightButtonDown = true
        let command = Command.mouse(action: .mousedown, button: .right)
        connectionManager.sendCommand(command)
    }

    func handleRightUp() {
        isRightButtonDown = false
        let command = Command.mouse(action: .mouseup, button: .right)
        connectionManager.sendCommand(command)
    }

    func handleScroll(delta: Int) {
        let scaledDelta = Int(Float(delta) * scrollSensitivity)
        guard scaledDelta != 0 else { return }
        let command = Command.mouse(action: .scroll, delta: scaledDelta)
        connectionManager.sendCommand(command)
    }

    func handleDragStart() {
        let command = Command.mouse(action: .dragStart, button: .left)
        connectionManager.sendCommand(command)
    }

    func handleDragEnd() {
        let command = Command.mouse(action: .dragEnd, button: .left)
        connectionManager.sendCommand(command)
    }
}
