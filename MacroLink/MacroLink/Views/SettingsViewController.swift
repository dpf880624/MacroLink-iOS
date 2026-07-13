import UIKit

class SettingsViewController: UITableViewController {
    private let cellId = "settingsCell"

    private struct SettingItem {
        let title: String
        let type: ItemType
        enum ItemType {
            case slider(key: String, min: Float, max: Float, step: Float, format: String)
            case toggle(key: String)
            case info(value: String)
        }
    }

    private let sections: [(String, [SettingItem])] = [
        ("触控板", [
            SettingItem(title: "鼠标灵敏度", type: .slider(key: "sensitivity", min: 0.1, max: 3.0, step: 0.1, format: "%.1f")),
            SettingItem(title: "滚轮灵敏度", type: .slider(key: "scrollSensitivity", min: 0.1, max: 3.0, step: 0.1, format: "%.1f")),
        ]),
        ("键盘", [
            SettingItem(title: "按键持续时间", type: .slider(key: "keyPressDuration", min: 10, max: 200, step: 10, format: "%.0f")),
            SettingItem(title: "触觉反馈", type: .toggle(key: "hapticEnabled")),
        ]),
        ("外观", [
            SettingItem(title: "RGB 灯效", type: .toggle(key: "rgbEnabled")),
            SettingItem(title: "显示PC状态", type: .toggle(key: "showPCStatus")),
        ]),
        ("关于", [
            SettingItem(title: "版本", type: .info(value: "1.0.0")),
            SettingItem(title: "协议版本", type: .info(value: "兼容 Android MacroLink")),
        ]),
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "设置"
        tableView.backgroundColor = .black
        tableView.separatorColor = UIColor(red: 0.3, green: 0.25, blue: 0.15, alpha: 0.3)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellId)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].1.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].0
    }

    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let header = view as? UITableViewHeaderFooterView {
            header.textLabel?.textColor = UIColor(red: 0.7, green: 0.65, blue: 0.5, alpha: 1.0)
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = sections[indexPath.section].1[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        cell.textLabel?.text = item.title
        cell.textLabel?.textColor = UIColor(red: 0.9, green: 0.85, blue: 0.7, alpha: 1.0)
        cell.backgroundColor = UIColor(red: 0.10, green: 0.10, blue: 0.12, alpha: 1.0)
        cell.selectionStyle = .none

        switch item.type {
        case .slider(let key, let min, let max, let step, let format):
            let slider = UISlider()
            slider.minimumValue = min
            slider.maximumValue = max
            slider.value = Float(UserDefaults.standard.double(forKey: key))
            slider.tintColor = UIColor(red: 0.9, green: 0.75, blue: 0.3, alpha: 1.0)
            slider.tag = indexPath.row
            slider.addTarget(self, action: #selector(sliderChanged(_:)), for: .valueChanged)
            objc_setAssociatedObject(slider, &AssocKeys.settingKey, key, .OBJC_ASSOCIATION_RETAIN)
            objc_setAssociatedObject(slider, &AssocKeys.settingFormat, format, .OBJC_ASSOCIATION_RETAIN)
            cell.accessoryView = slider
            cell.detailTextLabel?.text = String(format: format, slider.value)

        case .toggle(let key):
            let toggle = UISwitch()
            toggle.isOn = UserDefaults.standard.bool(forKey: key)
            toggle.onTintColor = UIColor(red: 0.9, green: 0.75, blue: 0.3, alpha: 1.0)
            objc_setAssociatedObject(toggle, &AssocKeys.settingKey, key, .OBJC_ASSOCIATION_RETAIN)
            toggle.addTarget(self, action: #selector(toggleChanged(_:)), for: .valueChanged)
            cell.accessoryView = toggle

        case .info(let value):
            let label = UILabel()
            label.text = value
            label.textColor = UIColor(red: 0.5, green: 0.45, blue: 0.3, alpha: 1.0)
            label.font = UIFont.systemFont(ofSize: 14)
            label.sizeToFit()
            cell.accessoryView = label
        }

        return cell
    }

    @objc private func sliderChanged(_ sender: UISlider) {
        guard let key = objc_getAssociatedObject(sender, &AssocKeys.settingKey) as? String else { return }
        UserDefaults.standard.set(Double(sender.value), forKey: key)
    }

    @objc private func toggleChanged(_ sender: UISwitch) {
        guard let key = objc_getAssociatedObject(sender, &AssocKeys.settingKey) as? String else { return }
        UserDefaults.standard.set(sender.isOn, forKey: key)
    }
}

private struct AssocKeys {
    nonisolated(unsafe) static var settingKey = "settingKey"
    nonisolated(unsafe) static var settingFormat = "settingFormat"
}