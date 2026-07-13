import UIKit

class MacroListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let viewModel = MacroViewModel()
    private var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "宏管理"
        view.backgroundColor = .black

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addMacro))
        navigationItem.rightBarButtonItem?.tintColor = UIColor(red: 0.9, green: 0.75, blue: 0.3, alpha: 1.0)

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "● 录制", style: .plain, target: self, action: #selector(toggleRecording))
        navigationItem.leftBarButtonItem?.tintColor = .red

        tableView = UITableView(frame: .zero, style: .plain)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .black
        tableView.separatorColor = UIColor(red: 0.3, green: 0.25, blue: 0.15, alpha: 0.3)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "macro")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        if viewModel.macros.isEmpty {
            let emptyLabel = UILabel()
            emptyLabel.text = "暂无宏\n点击 + 创建新宏"
            emptyLabel.numberOfLines = 0
            emptyLabel.textColor = UIColor(red: 0.5, green: 0.45, blue: 0.3, alpha: 1.0)
            emptyLabel.textAlignment = .center
            emptyLabel.font = UIFont.systemFont(ofSize: 16)
            emptyLabel.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(emptyLabel)
            NSLayoutConstraint.activate([
                emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            ])
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.macros.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "macro", for: indexPath)
        let macro = viewModel.macros[indexPath.row]
        cell.textLabel?.text = macro.name
        cell.textLabel?.textColor = UIColor(red: 0.9, green: 0.85, blue: 0.7, alpha: 1.0)
        cell.detailTextLabel?.text = "\(macro.actionCount) 步 ×\(macro.loopCount)"
        cell.detailTextLabel?.textColor = UIColor(red: 0.5, green: 0.45, blue: 0.3, alpha: 1.0)
        cell.backgroundColor = UIColor(red: 0.10, green: 0.10, blue: 0.12, alpha: 1.0)
        cell.selectionStyle = .none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let macro = viewModel.macros[indexPath.row]
        viewModel.playMacro(macro)
    }

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .destructive, title: "删除") { [weak self] _, index in
            guard let self = self else { return }
            self.viewModel.deleteMacro(self.viewModel.macros[index.row])
            self.tableView.reloadData()
        }
        return [delete]
    }

    @objc private func addMacro() {
        let alert = UIAlertController(title: "新建宏", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "宏名称" }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "创建", style: .default) { [weak self] _ in
            guard let name = alert.textFields?.first?.text, !name.isEmpty else { return }
            let macro = Macro(name: name)
            self?.viewModel.addMacro(macro)
            self?.tableView.reloadData()
        })
        present(alert, animated: true)
    }

    @objc private func toggleRecording() {
        if viewModel.isRecording {
            viewModel.stopRecording()
            navigationItem.leftBarButtonItem?.title = "● 录制"
        } else {
            viewModel.startRecording()
            navigationItem.leftBarButtonItem?.title = "■ 停止"
        }
    }
}