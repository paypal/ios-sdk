import Foundation

class MockPayPalAPIClient: PPCAPIClient {

    var validationResult: PPCValidationResult?
    var validationError: Error?

    override func validatePaymentMethod(_ paymentMethod: BTPaymentMethodNonce, forOrderId orderId: String, with3DS isThreeDSecureRequired: Bool, completion: @escaping (PPCValidationResult?, Error?) -> Void) {
        completion(validationResult, validationError)
    }
}
