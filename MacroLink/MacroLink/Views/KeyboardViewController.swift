import UIKit

class KeyboardViewController: UIViewController {
    private let viewModel = KeyboardViewModel()
    private var activeModifiers = Set<String>()
    private var scrollView: UIScrollView!
    private var keyboardStack: UIStackView!
    private var mediaBar: UIView!

    private let keySpacing: CGFloat = 3
    private let keyHeight: CGFloat = 42
    private let horizontalPadding: CGFloat = 8

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "键盘"
        view.backgroundColor = .black
        setupKeyboard()
        setupMediaBar()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutKeyboard()
    }

    private func setupKeyboard() {
        scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        keyboardStack = UIStackView()
        keyboardStack.axis = .vertical
        keyboardStack.spacing = keySpacing
        keyboardStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(keyboardStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -60),

            keyboardStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 4),
            keyboardStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: horizontalPadding),
            keyboardStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -horizontalPadding),
            keyboardStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -4),
            keyboardStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -horizontalPadding * 2),
        ])
    }

    private func layoutKeyboard() {
        keyboardStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let totalWidth = view.bounds.width - horizontalPadding * 2
        let row0Count: CGFloat = 14
        let standardWidth = (totalWidth - (row0Count - 1) * keySpacing) / row0Count

        for row in keyboardRows {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = keySpacing
            rowStack.alignment = .fill

            for key in row {
                let btn = createKeyButton(key: key, width: standardWidth * key.width)
                rowStack.addArrangedSubview(btn)
                btn.heightAnchor.constraint(equalToConstant: keyHeight).isActive = true
            }
            keyboardStack.addArrangedSubview(rowStack)
        }
    }

    private func createKeyButton(key: KeyDefinition, width: CGFloat) -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.10, alpha: 1.0)
        container.layer.cornerRadius = 4

        let keyView = UIView()
        keyView.backgroundColor = UIColor(red: 0.22, green: 0.20, blue: 0.25, alpha: 1.0)
        keyView.layer.cornerRadius = 3
        keyView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(keyView)

        let label = UILabel()
        label.text = key.label
        label.textColor = UIColor(red: 0.9, green: 0.85, blue: 0.7, alpha: 1.0)
        label.font = fontSize(for: key.label)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        keyView.addSubview(label)

        NSLayoutConstraint.activate([
            keyView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 2),
            keyView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -2),
            keyView.topAnchor.constraint(equalTo: container.topAnchor, constant: 2),
            keyView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -4),

            label.centerXAnchor.constraint(equalTo: keyView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: keyView.centerYAnchor),
        ])

        container.widthAnchor.constraint(equalToConstant: width).isActive = true

        let tapGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleKeyTouch(_:)))
        tapGesture.minimumPressDuration = 0
        container.addGestureRecognizer(tapGesture)
        container.tag = key.keyCode
        container.accessibilityLabel = key.label
        objc_setAssociatedObject(container, &AssociatedKeys.keyDef, key, .OBJC_ASSOCIATION_RETAIN)

        return container
    }

    private func fontSize(for label: String) -> UIFont {
        if label.count <= 1 { return UIFont.boldSystemFont(ofSize: 16) }
        if label.count <= 3 { return UIFont.boldSystemFont(ofSize: 13) }
        return UIFont.boldSystemFont(ofSize: 10)
    }

    @objc private func handleKeyTouch(_ gesture: UILongPressGestureRecognizer) {
        guard let keyView = gesture.view,
              let key = objc_getAssociatedObject(keyView, &AssociatedKeys.keyDef) as? KeyDefinition else { return }

        let innerView = keyView.subviews.first

        switch gesture.state {
        case .began:
            innerView?.backgroundColor = UIColor(red: 0.35, green: 0.30, blue: 0.15, alpha: 1.0)
            handleKeyPress(key)
        case .ended, .cancelled:
            innerView?.backgroundColor = UIColor(red: 0.22, green: 0.20, blue: 0.25, alpha: 1.0)
            handleKeyRelease(key)
        default:
            break
        }
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
    }

    private func setupMediaBar() {
        mediaBar = UIView()
        mediaBar.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.10, alpha: 1.0)
        mediaBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mediaBar)

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        mediaBar.addSubview(stack)

        let actions: [(String, MediaAction)] = [
            ("⏮", .previous),
            ("▶", .play),
            ("⏭", .next),
        ]

        for (icon, action) in actions {
            let btn = UIButton(type: .system)
            btn.setTitle(icon, for: .normal)
            btn.titleLabel?.font = UIFont.systemFont(ofSize: 18)
            btn.setTitleColor(UIColor(red: 0.9, green: 0.85, blue: 0.7, alpha: 1.0), for: .normal)
            btn.tag = action.hashValue
            btn.addTarget(self, action: #selector(mediaActionTapped(_:)), for: .touchUpInside)
            btn.widthAnchor.constraint(equalToConstant: 44).isActive = true
            btn.heightAnchor.constraint(equalToConstant: 44).isActive = true
            objc_setAssociatedObject(btn, &AssociatedKeys.mediaAction, action, .OBJC_ASSOCIATION_RETAIN)
            stack.addArrangedSubview(btn)
        }

        NSLayoutConstraint.activate([
            mediaBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mediaBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mediaBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            mediaBar.heightAnchor.constraint(equalToConstant: 60),

            stack.leadingAnchor.constraint(equalTo: mediaBar.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: mediaBar.trailingAnchor, constant: -20),
            stack.centerYAnchor.constraint(equalTo: mediaBar.centerYAnchor),
        ])
    }

    @objc private func mediaActionTapped(_ sender: UIButton) {
        guard let action = objc_getAssociatedObject(sender, &AssociatedKeys.mediaAction) as? MediaAction else { return }
        viewModel.sendMediaAction(action)
    }
}

private struct AssociatedKeys {
    nonisolated(unsafe) static var keyDef = "keyDef"
    nonisolated(unsafe) static var mediaAction = "mediaAction"
}