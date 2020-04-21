import Foundation

class MockCardClient: BTCardClient {
    
    var cardNonce: BTCardNonce?
    var tokenizeCardError: Error?
    
    override func tokenizeCard(_ card: BTCard, completion: @escaping (BTCardNonce?, Error?) -> Void) {
        completion(cardNonce, tokenizeCardError)
    }
}
