import XCTest

class PPCCardContingencyRequest_Tests: XCTestCase {

    let cardContingencyRequest = PPCCardContingencyRequest(contingencyURL: URL(string: "www.contingency.com")!)
    let apiClient = BTAPIClient(authorization: "development_tokenization_key")!
    let mockPaymentFlowDriverDelegate = MockPaymentFlowDriverDelegate()
    
    // MARK: - initializer
    
    func testInitWithContingencyURL_setsContingencyURL() {
        XCTAssertEqual(cardContingencyRequest.contingencyURL.absoluteString, "www.contingency.com")
    }
    
    // MARK: - handleRequest
    
    func testHandleRequest_callsOnPaymentWithURL_withProperContingencyURL() {
        BTAppSwitch.setReturnURLScheme("com.fake-return-url.scheme")

        let expectation = self.expectation(description: "Calls delegate's onPayment method with url")
        
        mockPaymentFlowDriverDelegate.onPaymentWithURLVerifier = { url, error in
            XCTAssertEqual(url?.absoluteString, "www.contingency.com?redirect_uri=com.fake-return-url.scheme://x-callback-url/braintree/paypal-validator")
            XCTAssertNil(error)
            expectation.fulfill()
        }
        
        cardContingencyRequest.handle(cardContingencyRequest, client: apiClient, paymentDriverDelegate: mockPaymentFlowDriverDelegate)
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    // MARK: - canHandleAppSwitchReturnURL
    
    func testCanHandleAppSwitchReturnURL_whenURLHasCorrectHostAndPath_returnsTrue() {
        XCTAssertTrue(cardContingencyRequest.canHandleAppSwitchReturn(URL(string: "com.braintreepayments.Demo.payments://x-callback-url/braintree/paypal-validator")!, sourceApplication: ""))
    }
    
    func testCanHandleAppSwitchReturnURL_whenURLHasUnrecognizedHost_returnFalse() {
        XCTAssertFalse(cardContingencyRequest.canHandleAppSwitchReturn(URL(string: "com.braintreepayments.Demo.payments://some-other-host/braintree/paypal-validator")!, sourceApplication: ""))
    }
    
    func testCanHandleAppSwitchReturnURL_whenURLHasUnrecognizedPath_returnFalse() {
        XCTAssertFalse(cardContingencyRequest.canHandleAppSwitchReturn(URL(string: "com.braintreepayments.Demo.payments://x-callback-url/some/other/path")!, sourceApplication: ""))
    }
    
    // MARK: - handleOpenURL
    
    func testHandleOpenURL_whenSuccessOccurred_callsOnPaymentCompleteWithResult() {
        let expectation = self.expectation(description: "Calls delegate's onPaymentComplete with result")
        
        mockPaymentFlowDriverDelegate.onPaymentCompleteVerifier = { result, error in
            guard let result = result as? PPCCardContingencyResult else { XCTFail(); return }
            
            XCTAssertEqual(result.state, "abc")
            XCTAssertNil(result.error)
            expectation.fulfill()
        }
        
        // This needs to be called first in order to set the delegate
        cardContingencyRequest.handle(cardContingencyRequest, client: apiClient, paymentDriverDelegate: mockPaymentFlowDriverDelegate)
        
        cardContingencyRequest.handleOpen(URL(string: "www.example.com?state=abc")!)
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testHandleOpenURL_whenErrorOccurred_callsOnPaymentCompleteWithError() {
        let expectation = self.expectation(description: "Calls delegate's onPaymentComplete with result")
        
        mockPaymentFlowDriverDelegate.onPaymentCompleteVerifier = { result, error in
            XCTAssertNil(result)
            XCTAssertEqual(error?.localizedDescription, "an error occurred")
            expectation.fulfill()
        }
        
        // This needs to be called first in order to set the delegate
        cardContingencyRequest.handle(cardContingencyRequest, client: apiClient, paymentDriverDelegate: mockPaymentFlowDriverDelegate)
        
        cardContingencyRequest.handleOpen(URL(string: "www.example.com?error=some%20error&error_description=an%20error%20occurred")!)
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    // MARK: - paymentFlowName
    
    func testPaymentFlowName() {
        XCTAssertEqual(cardContingencyRequest.paymentFlowName(), "paypal-commerce-platform-contingency")
    }
}
