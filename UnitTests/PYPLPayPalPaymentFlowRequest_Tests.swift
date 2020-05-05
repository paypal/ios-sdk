import XCTest

class PYPLPayPalPaymentFlowRequest_Tests: XCTestCase {

    let request = PYPLPayPalPaymentFlowRequest(checkoutURL: URL(string: "www.fake-checkout-url.com")!)
    let apiClient = BTAPIClient(authorization: "development_tokenization_key")!
    let mockPaymentFlowDriverDelegate = MockPaymentFlowDriverDelegate()

    // MARK: - initializer

    func testInitWithCheckoutURL_setsCheckoutURL() {
        XCTAssertEqual(request.checkoutURL.absoluteString, "www.fake-checkout-url.com")
    }

    // MARK: - handleRequest

    func testHandleRequest_callsOnPaymentWithURL_withProperCheckoutURL() {
        BTAppSwitch.setReturnURLScheme("com.fake-return-url.scheme")

        let expectation = self.expectation(description: "Calls delegate's onPayment method with url")

        mockPaymentFlowDriverDelegate.onPaymentWithURLVerifier = { url, error in
            XCTAssertEqual(url?.absoluteString, "www.fake-checkout-url.com?redirect_uri=com.fake-return-url.scheme://x-callback-url/paypal-sdk/paypal-checkout&native_xo=1")
            XCTAssertNil(error)
            expectation.fulfill()
        }

        request.handle(request, client: apiClient, paymentDriverDelegate: mockPaymentFlowDriverDelegate)
        waitForExpectations(timeout: 1.0, handler: nil)
    }

    // MARK: - canHandleAppSwitchReturnURL

    func testCanHandleAppSwitchReturnURL_whenURLHasCorrectHostAndPath_returnsTrue() {
        XCTAssertTrue(request.canHandleAppSwitchReturn(URL(string: "com.braintreepayments.Demo.payments://x-callback-url/paypal-sdk/paypal-checkout")!, sourceApplication: ""))
    }

    func testCanHandleAppSwitchReturnURL_whenURLHasUnrecognizedHost_returnFalse() {
        XCTAssertFalse(request.canHandleAppSwitchReturn(URL(string: "com.braintreepayments.Demo.payments://some-other-host/braintree/paypal-checkout")!, sourceApplication: ""))
    }

    func testCanHandleAppSwitchReturnURL_whenURLHasUnrecognizedPath_returnFalse() {
        XCTAssertFalse(request.canHandleAppSwitchReturn(URL(string: "com.braintreepayments.Demo.payments://x-callback-url/some/other/path")!, sourceApplication: ""))
    }

    // MARK: - handleOpenURL

    func testHandleOpenURL_whenSuccessOccurred_callsOnPaymentCompleteWithResult() {
        let expectation = self.expectation(description: "Calls delegate's onPaymentComplete with result")

        mockPaymentFlowDriverDelegate.onPaymentCompleteVerifier = { result, error in
            guard let result = result as? PYPLPayPalPaymentFlowResult else { XCTFail(); return }

            XCTAssertEqual(result.token, "my-order-id")
            XCTAssertEqual(result.payerID, "sally123")
            expectation.fulfill()
        }

        // This needs to be called first in order to set the delegate
        request.handle(request, client: apiClient, paymentDriverDelegate: mockPaymentFlowDriverDelegate)

        request.handleOpen(URL(string: "www.example.com?token=my-order-id&PayerID=sally123")!)

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testHandleOpenURL_whenErrorOccurred_callsOnPaymentCompleteWithError() {
        let expectation = self.expectation(description: "Calls delegate's onPaymentComplete with result")

        mockPaymentFlowDriverDelegate.onPaymentCompleteVerifier = { result, error in
            XCTAssertNil(result)
            XCTAssertEqual(error?.localizedDescription, "PayPal redirect URL error.")
            expectation.fulfill()
        }

        // This needs to be called first in order to set the delegate
        request.handle(request, client: apiClient, paymentDriverDelegate: mockPaymentFlowDriverDelegate)

        request.handleOpen(URL(string: "www.redirect-url-without-expected-params.com")!)

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    // MARK: - paymentFlowName

    func testPaymentFlowName() {
        XCTAssertEqual(request.paymentFlowName(), "paypal-commerce-platform-pwpp")
    }
}
