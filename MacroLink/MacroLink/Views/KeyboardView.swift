import SwiftUI

struct KeyboardView: View {
    @StateObject private var viewModel = KeyboardViewModel()
    @State private var activeModifiers: Set<String> = []

    var body: some View {
        VStack(spacing: 0) {
            ScrollView([.horizontal, .vertical], showsIndicators: false) {
                VStack(spacing: 3) {
                    ForEach(keyboardRows, id: \.first?.id) { row in
                        HStack(spacing: 3) {
                            ForEach(row) { key in
                                SteampunkKeycapButton(
                                    key: key,
                                    onPressed: { handleKeyPress(key) },
                                    onReleased: { handleKeyRelease(key) }
                                )
                                .frame(width: keyWidth(for: key), height: 42)
                            }
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }

            mediaControlBar
        }
        .background(Color.black)
    }

    private var mediaControlBar: some View {
        HStack(spacing: 16) {
            mediaButton(icon: "backward.fill", action: { viewModel.sendMediaAction(.previous) })
            mediaButton(icon: "play.fill", action: { viewModel.sendMediaAction(.play) })
            mediaButton(icon: "forward.fill", action: { viewModel.sendMediaAction(.next) })
            Spacer()
            mediaButton(icon: "speaker.wave.1.fill", action: { viewModel.sendMediaAction(.volume) })
            mediaButton(icon: "speaker.wave.3.fill", action: { viewModel.sendMediaAction(.volume) })
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color(red: 0.08, green: 0.08, blue: 0.10))
    }

    private func mediaButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Color(red: 0.9, green: 0.85, blue: 0.7))
        }
        .frame(width: 44, height: 44)
    }

    private func keyWidth(for key: KeyDefinition) -> CGFloat {
        let baseWidth: CGFloat = 30
        let spacing: CGFloat = 3
        let totalWidth = UIScreen.main.bounds.width - 16
        let row0Count: CGFloat = 14
        let standardWidth = (totalWidth - (row0Count - 1) * spacing) / row0Count
        return standardWidth * key.width
    }

    private func handleKeyPress(_ key: KeyDefinition) {
        if key.isModifier, let modName = key.modifierName {
            activeModifiers.insert(modName)
        } else {
            let mods = Array(activeModifiers)
            viewModel.sendKeyPress(keyCode: key.keyCode, modifiers: mods)
            activeModifiers.removeAll()
        }
    }

    private func handleKeyRelease(_ key: KeyDefinition) {
        if key.isModifier, let modName = key.modifierName {
            // Modifier stays active until next key press
        }
    }
}