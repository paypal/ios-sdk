import XCTest

class PYPLPayPalPaymentFlowResult_Tests: XCTestCase {

    func testPayPalPaymentFlowResult_initializesProperties_withSuccessResultURL() {
        let resultURL = URL.init(string: "scheme://x-callback-url/paypal-sdk/paypal-checkout?token=my-order-id&PayerID=sally123")!
        let result = PYPLPayPalPaymentFlowResult.init(url: resultURL)

        XCTAssertEqual(result.token, "my-order-id")
        XCTAssertEqual(result.payerID, "sally123")
    }
}
