import SwiftUI

struct SettingsView: View {
    @AppStorage("sensitivity") private var sensitivity: Double = 1.0
    @AppStorage("scrollSensitivity") private var scrollSensitivity: Double = 1.0
    @AppStorage("keyPressDuration") private var keyPressDuration: Double = 50
    @AppStorage("rgbEnabled") private var rgbEnabled: Bool = false
    @AppStorage("hapticEnabled") private var hapticEnabled: Bool = true
    @AppStorage("showPCStatus") private var showPCStatus: Bool = true

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                Form {
                    Section(header: Text("触控板").foregroundColor(Color(red: 0.7, green: 0.65, blue: 0.5))) {
                        VStack(alignment: .leading) {
                            Text("鼠标灵敏度: \(sensitivity, specifier: "%.1f")")
                                .foregroundColor(Color(red: 0.9, green: 0.85, blue: 0.7))
                            Slider(value: $sensitivity, in: 0.1...3.0, step: 0.1)
                                .tint(Color(red: 0.9, green: 0.75, blue: 0.3))
                        }
                        VStack(alignment: .leading) {
                            Text("滚轮灵敏度: \(scrollSensitivity, specifier: "%.1f")")
                                .foregroundColor(Color(red: 0.9, green: 0.85, blue: 0.7))
                            Slider(value: $scrollSensitivity, in: 0.1...3.0, step: 0.1)
                                .tint(Color(red: 0.9, green: 0.75, blue: 0.3))
                        }
                    }

                    Section(header: Text("键盘").foregroundColor(Color(red: 0.7, green: 0.65, blue: 0.5))) {
                        VStack(alignment: .leading) {
                            Text("按键持续时间: \(Int(keyPressDuration))ms")
                                .foregroundColor(Color(red: 0.9, green: 0.85, blue: 0.7))
                            Slider(value: $keyPressDuration, in: 10...200, step: 10)
                                .tint(Color(red: 0.9, green: 0.75, blue: 0.3))
                        }
                        Toggle("触觉反馈", isOn: $hapticEnabled)
                            .foregroundColor(Color(red: 0.9, green: 0.85, blue: 0.7))
                            .tint(Color(red: 0.9, green: 0.75, blue: 0.3))
                    }

                    Section(header: Text("外观").foregroundColor(Color(red: 0.7, green: 0.65, blue: 0.5))) {
                        Toggle("RGB 灯效", isOn: $rgbEnabled)
                            .foregroundColor(Color(red: 0.9, green: 0.85, blue: 0.7))
                            .tint(Color(red: 0.9, green: 0.75, blue: 0.3))
                        Toggle("显示PC状态", isOn: $showPCStatus)
                            .foregroundColor(Color(red: 0.9, green: 0.85, blue: 0.7))
                            .tint(Color(red: 0.9, green: 0.75, blue: 0.3))
                    }

                    Section(header: Text("关于").foregroundColor(Color(red: 0.7, green: 0.65, blue: 0.5))) {
                        HStack {
                            Text("版本")
                                .foregroundColor(Color(red: 0.9, green: 0.85, blue: 0.7))
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.3))
                        }
                        HStack {
                            Text("协议版本")
                                .foregroundColor(Color(red: 0.9, green: 0.85, blue: 0.7))
                            Spacer()
                            Text("兼容 Android MacroLink")
                                .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.3))
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color(red: 0.08, green: 0.08, blue: 0.10), for: .navigationBar)
        }
    }
}