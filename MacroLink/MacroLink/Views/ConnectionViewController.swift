import UIKit

class ConnectionViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let connectionManager = ConnectionManager.shared
    private var isScanning = false

    private var scrollView: UIScrollView!
    private var contentView: UIView!
    private var statusCard: UIView!
    private var statusLabel: UILabel!
    private var statusDot: UIView!
    private var scanButton: UIButton!
    private var serverCard: UIView!
    private var ipTextField: UITextField!
    private var portTextField: UITextField!
    private var serverPortTextField: UITextField!
    private var serverStatusLabel: UILabel!
    private var serverIPLabel: UILabel!
    private var devicesTableView: UITableView!
    private var connectButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "连接"
        view.backgroundColor = .black
        setupUI()
        NotificationCenter.default.addObserver(self, selector: #selector(refreshUI), name: NSNotification.Name("ConnectionStateChanged"), object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshUI()
    }

    private func setupUI() {
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)

        statusCard = createCard()
        statusDot = UIView()
        statusDot.layer.cornerRadius = 6
        statusDot.translatesAutoresizingMaskIntoConstraints = false
        statusCard.addSubview(statusDot)

        statusLabel = UILabel()
        statusLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        statusLabel.textColor = UIColor(red: 0.9, green: 0.85, blue: 0.7, alpha: 1.0)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusCard.addSubview(statusLabel)

        NSLayoutConstraint.activate([
            statusDot.leadingAnchor.constraint(equalTo: statusCard.leadingAnchor, constant: 16),
            statusDot.centerYAnchor.constraint(equalTo: statusCard.centerYAnchor),
            statusDot.widthAnchor.constraint(equalToConstant: 12),
            statusDot.heightAnchor.constraint(equalToConstant: 12),
            statusLabel.leadingAnchor.constraint(equalTo: statusDot.trailingAnchor, constant: 12),
            statusLabel.centerYAnchor.constraint(equalTo: statusCard.centerYAnchor),
        ])

        scanButton = UIButton(type: .system)
        scanButton.setTitle("扫描设备", for: .normal)
        scanButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        scanButton.setTitleColor(UIColor(red: 0.9, green: 0.75, blue: 0.3, alpha: 1.0), for: .normal)
        scanButton.backgroundColor = UIColor(red: 0.9, green: 0.75, blue: 0.3, alpha: 0.15)
        scanButton.layer.cornerRadius = 12
        scanButton.addTarget(self, action: #selector(toggleScan), for: .touchUpInside)
        scanButton.translatesAutoresizingMaskIntoConstraints = false
        scanButton.heightAnchor.constraint(equalToConstant: 48).isActive = true

        let manualCard = createCard()
        let manualTitle = UILabel()
        manualTitle.text = "手动连接"
        manualTitle.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        manualTitle.textColor = UIColor(red: 0.7, green: 0.65, blue: 0.5, alpha: 1.0)
        manualTitle.translatesAutoresizingMaskIntoConstraints = false
        manualCard.addSubview(manualTitle)

        ipTextField = createTextField("IP 地址")
        portTextField = createTextField("8888")
        portTextField.widthAnchor.constraint(equalToConstant: 70).isActive = true
        portTextField.keyboardType = .numberPad
        ipTextField.keyboardType = .decimalPad

        connectButton = UIButton(type: .system)
        connectButton.setTitle("→", for: .normal)
        connectButton.titleLabel?.font = UIFont.systemFont(ofSize: 24)
        connectButton.setTitleColor(UIColor(red: 0.9, green: 0.75, blue: 0.3, alpha: 1.0), for: .normal)
        connectButton.addTarget(self, action: #selector(manualConnect), for: .touchUpInside)

        let fieldStack = UIStackView(arrangedSubviews: [ipTextField, portTextField, connectButton])
        fieldStack.axis = .horizontal
        fieldStack.spacing = 8
        fieldStack.translatesAutoresizingMaskIntoConstraints = false
        manualCard.addSubview(fieldStack)

        NSLayoutConstraint.activate([
            manualTitle.topAnchor.constraint(equalTo: manualCard.topAnchor, constant: 12),
            manualTitle.leadingAnchor.constraint(equalTo: manualCard.leadingAnchor, constant: 16),
            fieldStack.topAnchor.constraint(equalTo: manualTitle.bottomAnchor, constant: 8),
            fieldStack.leadingAnchor.constraint(equalTo: manualCard.leadingAnchor, constant: 16),
            fieldStack.trailingAnchor.constraint(equalTo: manualCard.trailingAnchor, constant: -16),
            fieldStack.bottomAnchor.constraint(equalTo: manualCard.bottomAnchor, constant: -12),
        ])

        serverCard = createCard()
        let serverTitle = UILabel()
        serverTitle.text = "🖥 服务器模式"
        serverTitle.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        serverTitle.textColor = UIColor(red: 0.7, green: 0.65, blue: 0.5, alpha: 1.0)
        serverTitle.translatesAutoresizingMaskIntoConstraints = false
        serverCard.addSubview(serverTitle)

        serverPortTextField = createTextField("8888")
        serverPortTextField.keyboardType = .numberPad
        serverPortTextField.widthAnchor.constraint(equalToConstant: 70).isActive = true

        let serverStartBtn = UIButton(type: .system)
        serverStartBtn.setTitle("启动", for: .normal)
        serverStartBtn.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        serverStartBtn.setTitleColor(UIColor(red: 0.9, green: 0.75, blue: 0.3, alpha: 1.0), for: .normal)
        serverStartBtn.backgroundColor = UIColor(red: 0.9, green: 0.75, blue: 0.3, alpha: 0.15)
        serverStartBtn.layer.cornerRadius = 8
        serverStartBtn.addTarget(self, action: #selector(startServer), for: .touchUpInside)

        let serverFieldStack = UIStackView(arrangedSubviews: [serverPortTextField, serverStartBtn])
        serverFieldStack.axis = .horizontal
        serverFieldStack.spacing = 8
        serverFieldStack.translatesAutoresizingMaskIntoConstraints = false
        serverCard.addSubview(serverFieldStack)

        serverIPLabel = UILabel()
        serverIPLabel.font = UIFont.systemFont(ofSize: 12)
        serverIPLabel.textColor = UIColor(red: 0.9, green: 0.85, blue: 0.7, alpha: 1.0)
        serverIPLabel.translatesAutoresizingMaskIntoConstraints = false
        serverCard.addSubview(serverIPLabel)

        serverStatusLabel = UILabel()
        serverStatusLabel.font = UIFont.systemFont(ofSize: 12)
        serverStatusLabel.textColor = UIColor(red: 0.5, green: 0.45, blue: 0.3, alpha: 1.0)
        serverStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        serverCard.addSubview(serverStatusLabel)

        NSLayoutConstraint.activate([
            serverTitle.topAnchor.constraint(equalTo: serverCard.topAnchor, constant: 12),
            serverTitle.leadingAnchor.constraint(equalTo: serverCard.leadingAnchor, constant: 16),
            serverFieldStack.topAnchor.constraint(equalTo: serverTitle.bottomAnchor, constant: 8),
            serverFieldStack.leadingAnchor.constraint(equalTo: serverCard.leadingAnchor, constant: 16),
            serverFieldStack.trailingAnchor.constraint(equalTo: serverCard.trailingAnchor, constant: -16),
            serverIPLabel.topAnchor.constraint(equalTo: serverFieldStack.bottomAnchor, constant: 8),
            serverIPLabel.leadingAnchor.constraint(equalTo: serverCard.leadingAnchor, constant: 16),
            serverStatusLabel.topAnchor.constraint(equalTo: serverIPLabel.bottomAnchor, constant: 4),
            serverStatusLabel.leadingAnchor.constraint(equalTo: serverCard.leadingAnchor, constant: 16),
            serverStatusLabel.bottomAnchor.constraint(equalTo: serverCard.bottomAnchor, constant: -12),
        ])

        devicesTableView = UITableView(frame: .zero, style: .plain)
        devicesTableView.dataSource = self
        devicesTableView.delegate = self
        devicesTableView.backgroundColor = .clear
        devicesTableView.separatorStyle = .none
        devicesTableView.translatesAutoresizingMaskIntoConstraints = false
        devicesTableView.heightAnchor.constraint(equalToConstant: 200).isActive = true

        let mainStack = UIStackView(arrangedSubviews: [statusCard, scanButton, manualCard, serverCard, devicesTableView])
        mainStack.axis = .vertical
        mainStack.spacing = 16
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(mainStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
        ])
    }

    private func createCard() -> UIView {
        let card = UIView()
        card.backgroundColor = UIColor(red: 0.10, green: 0.10, blue: 0.12, alpha: 1.0)
        card.layer.cornerRadius = 12
        card.translatesAutoresizingMaskIntoConstraints = false
        return card
    }

    private func createTextField(_ placeholder: String) -> UITextField {
        let tf = UITextField()
        tf.placeholder = placeholder
        tf.backgroundColor = UIColor(red: 0.12, green: 0.12, blue: 0.14, alpha: 1.0)
        tf.layer.cornerRadius = 8
        tf.textColor = UIColor(red: 0.9, green: 0.85, blue: 0.7, alpha: 1.0)
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 1))
        tf.leftViewMode = .always
        return tf
    }

    @objc private func refreshUI() {
        let state = connectionManager.connectionState
        statusLabel.text = state.displayText

        switch state {
        case .connected:
            statusDot.backgroundColor = .green
        case .connecting, .scanning:
            statusDot.backgroundColor = .orange
        case .error:
            statusDot.backgroundColor = .red
        case .disconnected:
            statusDot.backgroundColor = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
        }

        if connectionManager.wifiServerRunning {
            serverIPLabel.text = "本机 IP: \(connectionManager.wifiServerIP ?? "未知")"
            serverStatusLabel.text = connectionManager.wifiServerClientConnected ? "PC 已连接" : "等待 PC 连接..."
            serverStatusLabel.textColor = connectionManager.wifiServerClientConnected ? .green : UIColor(red: 0.5, green: 0.45, blue: 0.3, alpha: 1.0)
        } else {
            serverIPLabel.text = ""
            serverStatusLabel.text = ""
        }

        devicesTableView.reloadData()
    }

    @objc private func toggleScan() {
        if isScanning {
            connectionManager.stopScan()
            isScanning = false
            scanButton.setTitle("扫描设备", for: .normal)
            scanButton.setTitleColor(UIColor(red: 0.9, green: 0.75, blue: 0.3, alpha: 1.0), for: .normal)
            scanButton.backgroundColor = UIColor(red: 0.9, green: 0.75, blue: 0.3, alpha: 0.15)
        } else {
            connectionManager.startScan()
            isScanning = true
            scanButton.setTitle("停止扫描", for: .normal)
            scanButton.setTitleColor(.red, for: .normal)
            scanButton.backgroundColor = UIColor.red.withAlphaComponent(0.15)
        }
    }

    @objc private func manualConnect() {
        guard let ip = ipTextField.text, !ip.isEmpty, let portStr = portTextField.text, let port = Int(portStr) else { return }
        let device = Device(id: "\(ip):\(port)", name: ip, ipAddress: ip, port: port, connectionType: .wifi)
        connectionManager.connect(to: device)
    }

    @objc private func startServer() {
        let port = UInt16(serverPortTextField.text ?? "8888") ?? Constants.defaultDataPort
        connectionManager.startWiFiServer(port: port)
        refreshUI()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return connectionManager.discoveredDevices.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "device")
        let device = connectionManager.discoveredDevices[indexPath.row]
        cell.textLabel?.text = device.name
        cell.textLabel?.textColor = UIColor(red: 0.9, green: 0.85, blue: 0.7, alpha: 1.0)
        cell.detailTextLabel?.text = device.ipAddress
        cell.detailTextLabel?.textColor = UIColor(red: 0.5, green: 0.45, blue: 0.3, alpha: 1.0)
        cell.backgroundColor = UIColor(red: 0.10, green: 0.10, blue: 0.12, alpha: 1.0)
        cell.selectionStyle = .none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let device = connectionManager.discoveredDevices[indexPath.row]
        connectionManager.connect(to: device)
    }
}