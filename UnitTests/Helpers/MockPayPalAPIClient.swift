import Foundation

class MockPayPalAPIClient: PYPLAPIClient {

    var validationResult: PYPLValidationResult?
    var validationError: Error?

    override func validatePaymentMethod(_ paymentMethod: BTPaymentMethodNonce, forOrderId orderId: String, with3DS isThreeDSecureRequired: Bool, completion: @escaping (PYPLValidationResult?, Error?) -> Void) {
        completion(validationResult, validationError)
    }
}
