import Foundation

class MockPaymentFlowDriverDelegate: BTPaymentFlowDriverDelegate {
    
    var onPaymentWithURLVerifier: ((URL?, Error?) -> Void)?
    var onPaymentCancelVerifier: (() -> Void)?
    var onPaymentCompleteVerifier: ((BTPaymentFlowResult?, Error?) -> Void)?
    
    func onPayment(with url: URL?, error: Error?) {
        onPaymentWithURLVerifier?(url, error)
    }
    
    func onPaymentCancel() {
        onPaymentCancelVerifier?()
    }
    
    func onPaymentComplete(_ result: BTPaymentFlowResult?, error: Error?) {
        onPaymentCompleteVerifier?(result, error)
    }
    
    func returnURLScheme() -> String {
        return ""
    }
    
    func apiClient() -> BTAPIClient {
        return BTAPIClient(authorization: "development_tokenization_key")!
    }
}
