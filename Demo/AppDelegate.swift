import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    private let urlScheme = "com.braintreepayments.Demo.payments" // TODO - change the URL scheme once SDK branding decided

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        BTAppSwitch.setReturnURLScheme(urlScheme)
        
        let settingsPlist = Bundle.main.url(forResource: "Settings", withExtension: "bundle")!.appendingPathComponent("Root.plist")
        let settingsDictionary = NSDictionary(contentsOf: settingsPlist)!
        let preferences = settingsDictionary["PreferenceSpecifiers"] as! [[String : Any]]
        
        var defaults: [String : Any] = [:]
        
        for preference in preferences {
            guard let key = preference["Key"] as? String else { continue }
            defaults[key] = preference["DefaultValue"]
        }
        UserDefaults.standard.register(defaults: defaults)
        
        if ProcessInfo.processInfo.arguments.contains("-Capture") {
            UserDefaults.standard.set("capture", forKey: "intent")
        } else if ProcessInfo.processInfo.arguments.contains("-Authorize") {
            UserDefaults.standard.set("authorize", forKey: "intent")
        }
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        guard url.scheme?.lowercased() == urlScheme.lowercased() else { return false }
        return BTAppSwitch.handleOpen(url, options: options)
    }
}
