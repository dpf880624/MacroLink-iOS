import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.tintColor = UIColor(red: 0.9, green: 0.75, blue: 0.3, alpha: 1.0)

        let tabBarController = MainTabBarController()
        window?.rootViewController = tabBarController
        window?.makeKeyAndVisible()

        UINavigationBar.appearance().barTintColor = UIColor(red: 0.08, green: 0.08, blue: 0.10, alpha: 1.0)
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor(red: 0.9, green: 0.85, blue: 0.7, alpha: 1.0)]
        UINavigationBar.appearance().isTranslucent = false

        return true
    }

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .all
    }
}