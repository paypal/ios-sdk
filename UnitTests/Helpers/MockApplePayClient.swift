import Foundation

class MockApplePayClient: BTApplePayClient {

    var paymentRequest: PKPaymentRequest?
    var paymentRequestError: Error?

    var applePayCardNonce: BTApplePayCardNonce?
    var tokenizeError: Error?
    
    override func paymentRequest(_ completion: @escaping (PKPaymentRequest?, Error?) -> Void) {
        completion(paymentRequest, paymentRequestError)
    }

    override func tokenizeApplePay(_ payment: PKPayment, completion completionBlock: @escaping (BTApplePayCardNonce?, Error?) -> Void) {
        completionBlock(applePayCardNonce, tokenizeError)
    }
}
