import Foundation

extension BTJSON {
    convenience init?(withJSONFile filename: String) {
        guard let path = Bundle(for: MockApplePayClient.self).path(forResource: filename, ofType: "json") else {
            print("File not found: \(filename).")
            return nil
        }
        
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe) else {
            print("Unable to read data in file: \(filename).")
            return nil
        }
        
        self.init(data: data)
    }
}
