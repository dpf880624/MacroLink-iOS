import UIKit

class MainTabBarController: UITabBarController {
    private let connectionManager = ConnectionManager.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        tabBar.barTintColor = UIColor(red: 0.06, green: 0.06, blue: 0.08, alpha: 1.0)
        tabBar.isTranslucent = false
        tabBar.tintColor = UIColor(red: 0.9, green: 0.75, blue: 0.3, alpha: 1.0)
        tabBar.unselectedItemTintColor = UIColor(red: 0.5, green: 0.45, blue: 0.3, alpha: 1.0)

        let keyboardVC = KeyboardViewController()
        keyboardVC.tabBarItem = UITabBarItem(title: "键盘", image: UIImage(named: "keyboard"), selectedImage: nil)
        if keyboardVC.tabBarItem.image == nil {
            keyboardVC.tabBarItem = UITabBarItem(title: "键盘", image: tabIcon("⌨"), tag: 0)
        }

        let touchpadVC = TouchpadViewController()
        touchpadVC.tabBarItem = UITabBarItem(title: "触控板", image: tabIcon("🖱"), tag: 1)

        let macroVC = MacroListViewController()
        macroVC.tabBarItem = UITabBarItem(title: "宏", image: tabIcon("📋"), tag: 2)

        let connectionVC = ConnectionViewController()
        connectionVC.tabBarItem = UITabBarItem(title: "连接", image: tabIcon("📡"), tag: 3)

        let settingsVC = SettingsViewController()
        settingsVC.tabBarItem = UITabBarItem(title: "设置", image: tabIcon("⚙"), tag: 4)

        viewControllers = [
            UINavigationController(rootViewController: keyboardVC),
            UINavigationController(rootViewController: touchpadVC),
            UINavigationController(rootViewController: macroVC),
            UINavigationController(rootViewController: connectionVC),
            UINavigationController(rootViewController: settingsVC),
        ]
    }

    private func tabIcon(_ emoji: String) -> UIImage? {
        let size = CGSize(width: 25, height: 25)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 20)]
        let str = NSString(string: emoji)
        str.draw(at: CGPoint(x: 2, y: -2), withAttributes: attrs)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image?.withRenderingMode(.alwaysOriginal)
    }
}

extension MainTabBarController: UITabBarControllerDelegate {
}