import XCTest

class PPCPayPalCheckoutResult_Tests: XCTestCase {

    func testPayPalCheckoutResult_initializesProperties_withSuccessResultURL() {
        let resultURL = URL.init(string: "scheme://x-callback-url/braintree/paypal-checkout?token=my-order-id&PayerID=sally123")!
        let checkoutResult = PPCPayPalCheckoutResult.init(url: resultURL)

        XCTAssertEqual(checkoutResult.token, "my-order-id")
        XCTAssertEqual(checkoutResult.payerID, "sally123")
    }
}
