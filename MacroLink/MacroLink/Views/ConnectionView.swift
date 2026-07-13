import SwiftUI

struct ConnectionView: View {
    @ObservedObject var connectionManager = ConnectionManager.shared
    @State private var isScanning: Bool = false
    @State private var manualIP: String = ""
    @State private var manualPort: String = "8888"
    @State private var serverPort: String = "8888"

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        connectionStatusCard

                        if connectionManager.connectionState.isConnected {
                            connectedDeviceCard
                        } else {
                            scanButton
                            serverModeCard
                            manualConnectCard
                            discoveredDevicesList
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("连接")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color(red: 0.08, green: 0.08, blue: 0.10), for: .navigationBar)
        }
    }

    private var connectionStatusCard: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(statusColor.opacity(0.3), lineWidth: 4)
                )

            Text(connectionManager.connectionState.displayText)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(red: 0.9, green: 0.85, blue: 0.7))

            Spacer()
        }
        .padding()
        .background(Color(red: 0.10, green: 0.10, blue: 0.12))
        .cornerRadius(12)
    }

    private var statusColor: Color {
        switch connectionManager.connectionState {
        case .connected: return .green
        case .connecting, .scanning: return .orange
        case .error: return .red
        case .disconnected: return Color(red: 0.4, green: 0.4, blue: 0.4)
        }
    }

    private var connectedDeviceCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "desktopcomputer")
                    .font(.system(size: 24))
                    .foregroundColor(Color(red: 0.9, green: 0.75, blue: 0.3))
                VStack(alignment: .leading) {
                    Text(connectionManager.connectedDevice?.name ?? "未知设备")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(red: 0.9, green: 0.85, blue: 0.7))
                    Text(connectionManager.connectedDevice?.ipAddress ?? "")
                        .font(.caption)
                        .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.3))
                }
                Spacer()
            }

            Button(action: { connectionManager.disconnect() }) {
                Text("断开连接")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.red.opacity(0.15))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(red: 0.10, green: 0.10, blue: 0.12))
        .cornerRadius(12)
    }

    private var scanButton: some View {
        Button(action: {
            if isScanning {
                connectionManager.stopScan()
                isScanning = false
            } else {
                connectionManager.startScan()
                isScanning = true
            }
        }) {
            HStack {
                Image(systemName: isScanning ? "stop.circle" : "antenna.radiowaves.left.and.right")
                Text(isScanning ? "停止扫描" : "扫描设备")
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(isScanning ? .red : Color(red: 0.9, green: 0.75, blue: 0.3))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isScanning ? Color.red.opacity(0.15) : Color(red: 0.9, green: 0.75, blue: 0.3).opacity(0.15))
            .cornerRadius(12)
        }
    }

    private var manualConnectCard: some View {
        VStack(spacing: 12) {
            Text("手动连接")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(red: 0.7, green: 0.65, blue: 0.5))
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                TextField("IP 地址", text: $manualIP)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(Color(red: 0.12, green: 0.12, blue: 0.14))
                    .cornerRadius(8)
                    .foregroundColor(Color(red: 0.9, green: 0.85, blue: 0.7))

                TextField("端口", text: $manualPort)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .frame(width: 70)
                    .background(Color(red: 0.12, green: 0.12, blue: 0.14))
                    .cornerRadius(8)
                    .foregroundColor(Color(red: 0.9, green: 0.85, blue: 0.7))

                Button(action: manualConnect) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color(red: 0.9, green: 0.75, blue: 0.3))
                }
            }
        }
        .padding()
        .background(Color(red: 0.10, green: 0.10, blue: 0.12))
        .cornerRadius(12)
    }

    private var serverModeCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "server.rack")
                    .font(.system(size: 16))
                    .foregroundColor(Color(red: 0.9, green: 0.75, blue: 0.3))
                Text("服务器模式")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(red: 0.7, green: 0.65, blue: 0.5))
                Spacer()
            }

            if connectionManager.wifiServerRunning {
                if let ip = connectionManager.wifiServerIP {
                    HStack {
                        Text("本机 IP:")
                            .font(.caption)
                            .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.3))
                        Text(ip)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(Color(red: 0.9, green: 0.85, blue: 0.7))
                            .textSelection(.enabled)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack(spacing: 8) {
                    Circle()
                        .fill(connectionManager.wifiServerClientConnected ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                    Text(connectionManager.wifiServerClientConnected ? "PC 已连接" : "等待 PC 连接...")
                        .font(.caption)
                        .foregroundColor(connectionManager.wifiServerClientConnected ? .green : Color(red: 0.5, green: 0.45, blue: 0.3))
                    Spacer()
                }

                Button(action: { connectionManager.stopWiFiServer() }) {
                    Text("停止服务器")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.red.opacity(0.15))
                        .cornerRadius(8)
                }
            } else {
                HStack(spacing: 8) {
                    Text("端口")
                        .font(.caption)
                        .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.3))
                    TextField("8888", text: $serverPort)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.plain)
                        .padding(8)
                        .frame(width: 70)
                        .background(Color(red: 0.12, green: 0.12, blue: 0.14))
                        .cornerRadius(6)
                        .foregroundColor(Color(red: 0.9, green: 0.85, blue: 0.7))
                    Spacer()
                    Button(action: startServer) {
                        HStack {
                            Image(systemName: "play.circle.fill")
                            Text("启动")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(red: 0.9, green: 0.75, blue: 0.3))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(red: 0.9, green: 0.75, blue: 0.3).opacity(0.15))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color(red: 0.10, green: 0.10, blue: 0.12))
        .cornerRadius(12)
    }

    private var discoveredDevicesList: some View {
        VStack(spacing: 8) {
            if connectionManager.discoveredDevices.isEmpty && isScanning {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.9, green: 0.75, blue: 0.3)))
                Text("正在搜索设备...")
                    .font(.caption)
                    .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.3))
            } else {
                ForEach(connectionManager.discoveredDevices) { device in
                    Button(action: { connectionManager.connect(to: device) }) {
                        HStack {
                            Image(systemName: "desktopcomputer")
                                .foregroundColor(Color(red: 0.9, green: 0.75, blue: 0.3))
                            VStack(alignment: .leading) {
                                Text(device.name)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(Color(red: 0.9, green: 0.85, blue: 0.7))
                                Text(device.ipAddress)
                                    .font(.caption)
                                    .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.3))
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(Color(red: 0.4, green: 0.35, blue: 0.2))
                        }
                        .padding()
                        .background(Color(red: 0.10, green: 0.10, blue: 0.12))
                        .cornerRadius(8)
                    }
                }
            }
        }
    }

    private func manualConnect() {
        guard !manualIP.isEmpty, let port = Int(manualPort) else { return }
        let device = Device(
            id: "\(manualIP):\(manualPort)",
            name: manualIP,
            ipAddress: manualIP,
            port: port,
            connectionType: .wifi
        )
        connectionManager.connect(to: device)
    }

    private func startServer() {
        let port = UInt16(serverPort) ?? Constants.defaultDataPort
        connectionManager.startWiFiServer(port: port)
    }
}