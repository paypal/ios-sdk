import Foundation

class DemoSettings {
    
    enum Environment: String {
        case local, sandbox, production
    }

    static var environment: Environment {
        UserDefaults.standard.string(forKey: "environment").flatMap( { Environment(rawValue: $0) }) ?? .sandbox
    }
    
    static var sampleMerchantServerURL: URL {
        switch environment {
        case .local:
            return URL(string: "http://localhost:5000")!
        case .sandbox:
            return URL(string: "https://ppcp-sample-merchant-sand.herokuapp.com")!
        case .production:
            return URL(string: "https://ppcp-sample-merchant-prod.herokuapp.com")!
        }
    }
    
    static var intent: String {
        UserDefaults.standard.string(forKey: "intent") ?? "capture"
    }
    
    static var countryCode: String {
        UserDefaults.standard.string(forKey: "countryCode") ?? "US"
    }
    
    static var currencyCode: String {
        countryCode == "US" ? "USD" : "GBP"
    }
    
    static var payeeEmailAddress: String {
        if environment == .local {
            if countryCode == "UK" {
                return "native-sdk-gb-merchant-111@paypal.com"
            } else {
                return "ahuang-us-bus-ppcp-approve-seller7@paypal.com"
            }
        } else if environment == .sandbox {
            if countryCode == "US" {
                return "ahuang-ppcp-demo-sb1@paypal.com"
            } // TODO obtain UK merchant account credentials
        }
        return "default-email@paypal.com"
    }
}
