import Foundation

class IntegrationTests_MerchantAPI {

    static let sharedService = IntegrationTests_MerchantAPI()

    private init() {}

    func generateOrderID(completion: @escaping ((String?, Error?) -> Void)) {
        var components = URLComponents(url: URL(string: "https://ppcp-sample-merchant-sand.herokuapp.com")!, resolvingAgainstBaseURL: false)!
        components.path = "/order"
        components.queryItems = [URLQueryItem(name: "countryCode", value: "US")]

        var urlRequest = URLRequest(url: components.url!)
        urlRequest.httpMethod = "POST"

        let dict: [String: Any] = [
            "intent": "CAPTURE",
            "purchase_units": [
                [
                    "amount": [
                        "currency_code": "EUR",
                        "value": "10.00"
                    ]
                ]
            ],
            "payee": [
                "email_address": "ahuang-ppcp-demo-sb1@paypal.com"
            ]
        ]

        guard let httpBody = try? JSONSerialization.data(withJSONObject: dict, options: []) else {
            completion(nil, nil)
            return
        }

        urlRequest.httpBody = httpBody
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            guard let data = data, error == nil else {
                completion(nil, error!)
                return
            }

            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary
                let orderID = json?.value(forKey: "id")
                completion(orderID as? String, nil)
            } catch (let error) {
                completion(nil, error)
            }
        }.resume()
    }

    func generateUAT(completion: @escaping ((String?, Error?) -> Void)) {
        var components = URLComponents(url: URL(string: "https://ppcp-sample-merchant-sand.herokuapp.com")!, resolvingAgainstBaseURL: false)!
        components.path = "/id-token"
        components.queryItems = [URLQueryItem(name: "countryCode", value: "US")]

        var urlRequest = URLRequest(url: components.url!)
        urlRequest.httpMethod = "GET"

        URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            guard let data = data, error == nil else {
                completion(nil, error!)
                return
            }

            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary
                let idToken = json?.value(forKey: "id_token")
                completion(idToken as? String, nil)
            } catch (let error) {
                completion(nil, error)
            }
        }.resume()
    }

}
