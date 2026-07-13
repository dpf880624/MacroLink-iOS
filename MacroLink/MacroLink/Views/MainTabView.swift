import SwiftUI

struct MainTabView: View {
    @ObservedObject var connectionManager = ConnectionManager.shared
    @State private var selectedTab: Tab = .keyboard

    enum Tab: CaseIterable {
        case keyboard
        case touchpad
        case macro
        case connection
        case settings

        var title: String {
            switch self {
            case .keyboard: return "键盘"
            case .touchpad: return "触控板"
            case .macro: return "宏"
            case .connection: return "连接"
            case .settings: return "设置"
            }
        }

        var icon: String {
            switch self {
            case .keyboard: return "keyboard"
            case .touchpad: return "cursorarrow.motion"
            case .macro: return "list.bullet.rectangle"
            case .connection: return "antenna.radiowaves.left.and.right"
            case .settings: return "gearshape"
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            tabContent
            tabBar
        }
        .background(Color.black.ignoresSafeArea())
    }

    private var tabContent: some View {
        Group {
            switch selectedTab {
            case .keyboard:
                KeyboardView()
            case .touchpad:
                TouchpadView()
            case .macro:
                MacroListView()
            case .connection:
                ConnectionView()
            case .settings:
                SettingsView()
            }
        }
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    VStack(spacing: 4) {
                        ZStack {
                            if tab == .connection {
                                Circle()
                                    .fill(connectionManager.connectionState.isConnected ? Color.green : Color.red)
                                    .frame(width: 6, height: 6)
                                    .offset(x: 10, y: -4)
                            }

                            Image(systemName: tab.icon)
                                .font(.system(size: 20))
                        }
                        Text(tab.title)
                            .font(.system(size: 10))
                    }
                    .foregroundColor(selectedTab == tab ? Color(red: 0.9, green: 0.75, blue: 0.3) : Color(red: 0.5, green: 0.45, blue: 0.3))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
        }
        .padding(.bottom, 2)
        .background(
            Color(red: 0.06, green: 0.06, blue: 0.08)
                .overlay(
                    Rectangle()
                        .fill(Color(red: 0.3, green: 0.25, blue: 0.15).opacity(0.3))
                        .frame(height: 0.5),
                    alignment: .top
                )
        )
    }
}