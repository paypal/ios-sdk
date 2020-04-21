import Foundation

class MockViewControllerPresentingDelegate: NSObject, BTViewControllerPresentingDelegate {
    
    var onPaymentDriverRequestsPresentation: ((Any, UIViewController) -> Void)?
    var onPaymentDriverRequestsDismissal: ((Any, UIViewController) -> Void)?
    
    func paymentDriver(_ driver: Any, requestsPresentationOf viewController: UIViewController) {
        onPaymentDriverRequestsPresentation?(driver, viewController)
    }
    
    func paymentDriver(_ driver: Any, requestsDismissalOf viewController: UIViewController) {
        onPaymentDriverRequestsDismissal?(driver, viewController)
    }
}
