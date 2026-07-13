import UIKit

class TouchpadViewController: UIViewController {
    private let viewModel = TouchpadViewModel()
    private var touchpadView: UIView!
    private var lastPosition: CGPoint = .zero
    private var isDragging = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "触控板"
        view.backgroundColor = .black
        setupTouchpad()
        setupMouseButtons()
    }

    private func setupTouchpad() {
        touchpadView = UIView()
        touchpadView.backgroundColor = UIColor(red: 0.10, green: 0.10, blue: 0.12, alpha: 1.0)
        touchpadView.layer.cornerRadius = 8
        touchpadView.layer.borderColor = UIColor(red: 0.4, green: 0.35, blue: 0.2, alpha: 0.5).cgColor
        touchpadView.layer.borderWidth = 1
        touchpadView.translatesAutoresizingMaskIntoConstraints = false

        let hintLabel = UILabel()
        hintLabel.text = "🖱 触控板"
        hintLabel.textColor = UIColor(red: 0.5, green: 0.45, blue: 0.3, alpha: 0.3)
        hintLabel.font = UIFont.systemFont(ofSize: 16)
        hintLabel.textAlignment = .center
        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        touchpadView.addSubview(hintLabel)

        NSLayoutConstraint.activate([
            hintLabel.centerXAnchor.constraint(equalTo: touchpadView.centerXAnchor),
            hintLabel.centerYAnchor.constraint(equalTo: touchpadView.centerYAnchor),
        ])

        view.addSubview(touchpadView)

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        touchpadView.addGestureRecognizer(panGesture)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        touchpadView.addGestureRecognizer(tapGesture)

        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTapGesture.numberOfTapsRequired = 2
        touchpadView.addGestureRecognizer(doubleTapGesture)

        tapGesture.require(toFail: doubleTapGesture)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        NSLayoutConstraint.activate([
            touchpadView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            touchpadView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            touchpadView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            touchpadView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -60),
        ])
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            isDragging = true
            lastPosition = gesture.location(in: touchpadView)
        case .changed:
            let current = gesture.location(in: touchpadView)
            let dx = current.x - lastPosition.x
            let dy = current.y - lastPosition.y
            lastPosition = current
            viewModel.handleMove(dx: dx, dy: dy)
        case .ended, .cancelled:
            isDragging = false
        default:
            break
        }
    }

    @objc private func handleTap() {
        viewModel.handleTap()
    }

    @objc private func handleDoubleTap() {
        viewModel.handleRightClick()
    }

    private func setupMouseButtons() {
        let buttonBar = UIView()
        buttonBar.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.10, alpha: 1.0)
        buttonBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonBar)

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 1
        stack.translatesAutoresizingMaskIntoConstraints = false
        buttonBar.addSubview(stack)

        let leftBtn = createMouseButton("左键")
        leftBtn.addTarget(self, action: #selector(leftDown), for: .touchDown)
        leftBtn.addTarget(self, action: #selector(leftUp), for: .touchUpInside)
        leftBtn.addTarget(self, action: #selector(leftUp), for: .touchUpOutside)

        let scrollBtn = createMouseButton("⇅")
        scrollBtn.addTarget(self, action: #selector(scrollUp), for: .touchDown)

        let rightBtn = createMouseButton("右键")
        rightBtn.addTarget(self, action: #selector(rightClick), for: .touchUpInside)

        stack.addArrangedSubview(leftBtn)
        stack.addArrangedSubview(scrollBtn)
        stack.addArrangedSubview(rightBtn)

        NSLayoutConstraint.activate([
            buttonBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            buttonBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            buttonBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            buttonBar.heightAnchor.constraint(equalToConstant: 50),

            stack.leadingAnchor.constraint(equalTo: buttonBar.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: buttonBar.trailingAnchor),
            stack.topAnchor.constraint(equalTo: buttonBar.topAnchor),
            stack.bottomAnchor.constraint(equalTo: buttonBar.bottomAnchor),
        ])
    }

    private func createMouseButton(_ title: String) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        btn.setTitleColor(UIColor(red: 0.7, green: 0.65, blue: 0.5, alpha: 1.0), for: .normal)
        btn.backgroundColor = UIColor(red: 0.15, green: 0.14, blue: 0.17, alpha: 1.0)
        return btn
    }

    @objc private func leftDown() { viewModel.handleLeftDown() }
    @objc private func leftUp() { viewModel.handleLeftUp() }
    @objc private func rightClick() { viewModel.handleRightClick() }
    @objc private func scrollUp() { viewModel.handleScroll(delta: 120) }
}