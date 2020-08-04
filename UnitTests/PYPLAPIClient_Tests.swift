import XCTest

class PYPLAPIClient_Tests: XCTestCase {
  
    let idTokenParams: [String : Any] = [
        "iss": "https://api.sandbox.paypal.com",
        "sub": "PayPal:fake-pp-merchant",
        "acr": [
            "client"
        ],
        "scopes": [
            "Braintree:Vault"
        ],
        "exp": 1571980506,
        "external_id": [
            "PayPal:fake-pp-merchant",
            "Braintree:fake-bt-merchant"
        ],
        "jti": "fake-jti"
    ]
    
    var idTokenString: String!
    var payPalAPIClient: PYPLAPIClient!
    var mockBTAPIClient: MockBTAPIClient!
    
    let nonce = BTPayPalAccountNonce(nonce: "paypal-nonce", localizedDescription: "PayPal Account Nonce")!
    let mockURLSession = MockURLSession()
    
    override func setUp() {
        super.setUp()
        idTokenString = PayPalIDTokenTestHelper.encodeToken(idTokenParams)
        mockBTAPIClient = MockBTAPIClient(authorization: idTokenString)
        
        payPalAPIClient = PYPLAPIClient(idToken: idTokenString)!
        payPalAPIClient.urlSession = mockURLSession
        payPalAPIClient.braintreeAPIClient = mockBTAPIClient
    }
    
    // MARK: - initialization

    func testInitWithIDTokenToken_returnsAPIClient() {
        XCTAssertNotNil(PYPLAPIClient(idToken: idTokenString))
    }
    
    func testInitWithInvalidIDToken_returnsNil() {
        XCTAssertNil(PYPLAPIClient(idToken: "invalid-token"))
    }

    // MARK: -  validatePaymentMethod

    func testValidatePaymentMethod_constructsURLRequest_with3DSRequested() {
        let expectation = self.expectation(description: "Calls URLSession with URLRequest")

        mockURLSession.data = try! BTJSON().asJSON()
        mockURLSession.urlResponse = HTTPURLResponse(url: URL(string: "www.example.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)

        mockURLSession.onDataTaskWithRequest = { request in
            guard let body = request.httpBody else { XCTFail(); return }
            
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.absoluteString, "https://api.sandbox.paypal.com/v2/checkout/orders/order-id/validate-payment-method")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer \(self.idTokenString!)")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
            XCTAssertEqual(body, try! BTJSON(withJSONFile: "paypal-validate-request-with-3ds")?.asJSON())
            expectation.fulfill()
        }

        payPalAPIClient.validatePaymentMethod(nonce, forOrderId: "order-id", with3DS: true, completion: { _, _ in })

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testValidatePaymentMethod_constructsURLRequest_without3DSRequested() {
        let expectation = self.expectation(description: "Calls URLSession with URLRequest")

        mockURLSession.data = try! BTJSON().asJSON()
        mockURLSession.urlResponse = HTTPURLResponse(url: URL(string: "www.example.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)

        mockURLSession.onDataTaskWithRequest = { request in
            guard let body = request.httpBody else { XCTFail(); return }

            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.absoluteString, "https://api.sandbox.paypal.com/v2/checkout/orders/order-id/validate-payment-method")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer \(self.idTokenString!)")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
            XCTAssertEqual(body, try! BTJSON(withJSONFile: "paypal-validate-request-without-3ds")?.asJSON())
            expectation.fulfill()
        }

        payPalAPIClient.validatePaymentMethod(nonce, forOrderId: "order-id", with3DS: false, completion: { _, _ in })

        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testValidatePaymentMethod_whenResponseCodeIs200_callsCompletionWithValidationResult() {
        let expectation = self.expectation(description: "Calls completion with PYPLValidationResult")

        mockURLSession.data = try! BTJSON(withJSONFile: "paypal-validation-response-without-contingency")?.asJSON()
        mockURLSession.urlResponse = HTTPURLResponse(url: URL(string: "www.example.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)

        payPalAPIClient.validatePaymentMethod(nonce, forOrderId: "order-id", with3DS: false) { (result, error) in
            XCTAssertNotNil(result)
            XCTAssertNil(result?.contingencyURL)
            XCTAssertNil(error)
            XCTAssertNotNil(self.mockBTAPIClient.postedAnalyticsEvents["ios.paypal-sdk.validate.succeeded"])
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testValidatePaymentMethod_whenResponseCodeIs422_andContingencyIsPresent_callsCompletionWithValidationResult() {
        let expectation = self.expectation(description: "Calls completion with PYPLValidationResult")

        mockURLSession.data = try! BTJSON(withJSONFile: "paypal-validation-response-with-contingency")?.asJSON()
        mockURLSession.urlResponse = HTTPURLResponse(url: URL(string: "www.example.com")!, statusCode: 422, httpVersion: nil, headerFields: nil)

        payPalAPIClient.validatePaymentMethod(nonce, forOrderId: "order-id", with3DS: true) { (result, error) in
            XCTAssertNotNil(result)
            XCTAssertEqual(result?.contingencyURL?.absoluteString, "www.contingency.com")
            XCTAssertEqual(result?.issueType, "CONTINGENCY")
            XCTAssertEqual(result?.message, "The requested action could not be performed, semantically incorrect, or failed business validation.")
            XCTAssertNil(error)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testValidatePaymentMethod_whenResponseCodeIs422_andCardExpiredResponse_callsCompletionWithError() {
        let expectation = self.expectation(description: "Calls completion with error")

        mockURLSession.data = try! BTJSON(withJSONFile: "paypal-validation-response-card-expired")?.asJSON()
        mockURLSession.urlResponse = HTTPURLResponse(url: URL(string: "www.example.com")!, statusCode: 422, httpVersion: nil, headerFields: nil)

        payPalAPIClient.validatePaymentMethod(nonce, forOrderId: "order-id", with3DS: false) { (result, error) in
            XCTAssertNil(result)
            XCTAssertEqual(error?.localizedDescription, "CARD_EXPIRED")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testValidatePaymentMethod_whenResponseCodeIs403_andInvalidTokenResponse_callsCompletionWithError() {
        let expectation = self.expectation(description: "Calls completion with error")

        mockURLSession.data = try! BTJSON(withJSONFile: "paypal-validation-response-invalid-token")?.asJSON()
        mockURLSession.urlResponse = HTTPURLResponse(url: URL(string: "www.example.com")!, statusCode: 403, httpVersion: nil, headerFields: nil)

        payPalAPIClient.validatePaymentMethod(nonce, forOrderId: "order-id", with3DS: false) { (result, error) in
            XCTAssertNil(result)
            XCTAssertEqual(error?.localizedDescription, "Token signature verification failed")
//            XCTAssertTrue(self.mockBTAPIClient.postedAnalyticsEvents.contains("ios.paypal-sdk.validate.failed"))
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testValidatePaymentMethod_whenValidateFailsWithError_callsCompletionWithError() {
        let expectation = self.expectation(description: "Calls completion with error")

        mockURLSession.data = nil
        mockURLSession.urlResponse = nil
        mockURLSession.error = NSError(domain: "Some error domain", code: 5, userInfo: [NSLocalizedDescriptionKey: "An error occurred"])

        payPalAPIClient.validatePaymentMethod(nonce, forOrderId: "order-id", with3DS: false) { (result, error) in
            XCTAssertNil(result)
            XCTAssertEqual(error?.localizedDescription, "An error occurred")
//            XCTAssertTrue(self.mockBTAPIClient.postedAnalyticsEvents.contains("ios.paypal-sdk.validate.failed"))
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0, handler: nil)
    }
}
