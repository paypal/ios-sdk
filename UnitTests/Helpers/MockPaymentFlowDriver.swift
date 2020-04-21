import Foundation

class MockPaymentFlowDriver: BTPaymentFlowDriver {

    var paymentFlowResult: BTPaymentFlowResult?
    var paymentFlowError: Error?
    
    var onStartPaymentFlow: ((BTPaymentFlowRequest) -> Void)?
    
    override func startPaymentFlow(_ request: BTPaymentFlowRequest & BTPaymentFlowRequestDelegate, completion completionBlock: @escaping (BTPaymentFlowResult?, Error?) -> Void) {
        onStartPaymentFlow?(request)
        completionBlock(paymentFlowResult, paymentFlowError)
    }
}
