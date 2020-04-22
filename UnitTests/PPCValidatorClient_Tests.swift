import XCTest

class PPCValidatorClient_Tests: XCTestCase {

    let uatParams: [String : Any] = [
      "iss": "https://api.sandbox.paypal.com",
      "external_ids": [
        "Braintree:merchant-id"
      ]
    ]
    
    var uatString: String!
    
    var validatorClient: PPCValidatorClient!
    let paymentRequest = PKPaymentRequest()

    var mockBTAPIClient: MockBTAPIClient!
    let mockPayPalAPIClient = MockPayPalAPIClient()
    var mockApplePayClient: MockApplePayClient!
    var mockCardClient: MockCardClient!
    var mockPaymentFlowDriver: MockPaymentFlowDriver!
    let mockViewControllerPresentingDelegate = MockViewControllerPresentingDelegate()

    override func setUp() {
        uatString = PayPalUATTestHelper.encodeUAT(uatParams)
        
        validatorClient = PPCValidatorClient(accessToken: uatString)
        mockBTAPIClient = MockBTAPIClient(authorization: uatString)
        
        let defaultPaymentRequest = PKPaymentRequest()
        defaultPaymentRequest.countryCode = "US"
        defaultPaymentRequest.currencyCode = "USD"
        defaultPaymentRequest.merchantIdentifier = "merchant-id"
        defaultPaymentRequest.supportedNetworks = [PKPaymentNetwork.visa]

        let applePayCardNonce = BTApplePayCardNonce(nonce: "apple-pay-nonce", localizedDescription: "a great nonce")
        
        mockApplePayClient = MockApplePayClient(apiClient: mockBTAPIClient)
        mockApplePayClient.paymentRequest = defaultPaymentRequest
        mockApplePayClient.applePayCardNonce = applePayCardNonce

        mockCardClient = MockCardClient(apiClient: mockBTAPIClient)
        mockCardClient.cardNonce = BTCardNonce(nonce: "card-nonce", localizedDescription: "another great nonce")
        
        mockPaymentFlowDriver = MockPaymentFlowDriver(apiClient: mockBTAPIClient)
        
        validatorClient?.applePayClient = mockApplePayClient
        validatorClient?.payPalAPIClient = mockPayPalAPIClient
        validatorClient?.cardClient = mockCardClient
        validatorClient?.braintreeAPIClient = mockBTAPIClient
        validatorClient?.paymentFlowDriver = mockPaymentFlowDriver
        validatorClient?.presentingDelegate = mockViewControllerPresentingDelegate
        
        paymentRequest.paymentSummaryItems = [PKPaymentSummaryItem(label: "item", amount: 1.00)]
        paymentRequest.merchantCapabilities = PKMerchantCapability.capabilityCredit
    }

    override func tearDown() {
        mockBTAPIClient.postedAnalyticsEvents.removeAll()
    }

    // MARK: - initWithAccessToken

    func testValidatorClientInitialization_withUAT_initializesAllProperties() {
        let validatorClient = PPCValidatorClient(accessToken: uatString)
        XCTAssertNotNil(validatorClient)
        XCTAssertNotNil(validatorClient?.payPalAPIClient)
        XCTAssertNotNil(validatorClient?.braintreeAPIClient)
        XCTAssertNotNil(validatorClient?.paymentFlowDriver)
        XCTAssertNotNil(validatorClient?.cardClient)
        XCTAssertNotNil(validatorClient?.applePayClient)
        XCTAssertNotNil(validatorClient?.payPalUAT)
    }

    func testValidatorClientInitialization_withInvalidUAT_returnsNil() {
        let validatorClient = PPCValidatorClient(accessToken: "header.invalid_paypal_uat_body.signature")
        XCTAssertNil(validatorClient)
    }
    
    // MARK: - checkoutWithApplePay
    
    func testCheckoutWithApplePay_whenDefaultPaymentRequestIsAvailable_requestsPresentationOfViewController() {
        let expectation = self.expectation(description: "passes Apple Pay view controller to merchant")
        
        mockViewControllerPresentingDelegate.onPaymentDriverRequestsPresentation = { driver, viewController in
            XCTAssertEqual(driver as? PPCValidatorClient, self.validatorClient)
            XCTAssertNotNil(viewController)
            XCTAssertTrue(viewController is PKPaymentAuthorizationViewController)
            expectation.fulfill()
        }

        validatorClient?.checkoutWithApplePay(orderID: "my-order-id", paymentRequest: paymentRequest) { (_, _, _) in
            // not called
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testCheckoutWithApplePay_whenDefaultPaymentRequestIsNotAvailable_returnsError() {
        self.mockApplePayClient.paymentRequestError = NSError(domain: "error", code: 0, userInfo: [NSLocalizedDescriptionKey: "error message"])
        self.mockApplePayClient.paymentRequest = nil

        let expectation = self.expectation(description: "returns Apple Pay error to merchant")

        validatorClient?.checkoutWithApplePay(orderID: "my-order-id", paymentRequest: PKPaymentRequest()) { (validatorResult, error, handler) in
            XCTAssertEqual(error?.localizedDescription, "error message")
            XCTAssertNil(validatorResult)
            XCTAssertNil(handler)

            XCTAssert(self.mockBTAPIClient.postedAnalyticsEvents.contains("ios.paypal-commerce-platform.apple-pay-payment-request.failed"))
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testCheckoutWithApplePay_callsPayPalDataCollector_getClientMetadataID() {
        PPCValidatorClient.setPayPalDataCollectorClass(MockPPDataCollector.self)

        let expectation = self.expectation(description: "calls PPDataCollector.clientMetadataId()")

        mockViewControllerPresentingDelegate.onPaymentDriverRequestsPresentation = { _, _ in
            XCTAssertTrue(MockPPDataCollector.didFetchClientMetadataID)
            expectation.fulfill()
        }

        validatorClient?.checkoutWithApplePay(orderID: "fake-order", paymentRequest: paymentRequest) { (_, _, _) in }

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    // MARK: - paymentAuthorizationViewControllerDidAuthorizePayment (iOS 11+)

    func testPaymentAuthorizationViewControllerDidAuthorizePayment_callsCompletionWithValidatorResult() {
        if #available(iOS 11.0, *) {
            let expectation = self.expectation(description: "payment authorization delegate calls completion with validator result")
            
            mockPayPalAPIClient.validationResult = PPCValidationResult()
            
            validatorClient?.checkoutWithApplePay(orderID: "fake-order", paymentRequest: paymentRequest) { (validatorResult, error, handler) in
                XCTAssertEqual(validatorResult?.orderID, "fake-order")
                XCTAssertEqual(validatorResult?.type, .applePay)
                XCTAssertNil(error)
                XCTAssertNotNil(handler)
                
                XCTAssert(self.mockBTAPIClient.postedAnalyticsEvents.contains("ios.paypal-commerce-platform.apple-pay-checkout.started"))
                XCTAssert(self.mockBTAPIClient.postedAnalyticsEvents.contains("ios.paypal-commerce-platform.apple-pay-checkout.succeeded"))
                expectation.fulfill()
            }
            
            let delegate = validatorClient as? PKPaymentAuthorizationViewControllerDelegate
            delegate?.paymentAuthorizationViewController?(PKPaymentAuthorizationViewController(), didAuthorizePayment: PKPayment(), handler: { _ in })
            
            waitForExpectations(timeout: 1.0, handler: nil)
        }
    }

    func testPaymentAuthorizationViewControllerDidAuthorizePayment_whenApplePayTokenizationFails_callsCompletionWithError() {
        if #available(iOS 11.0, *) {
            let expectation = self.expectation(description: "payment authorization delegate calls completion with error")
            
            mockApplePayClient.applePayCardNonce = nil
            mockApplePayClient.tokenizeError = NSError(domain: "some-domain", code: 1, userInfo: [NSLocalizedDescriptionKey: "BT tokenization error"])
            
            validatorClient?.checkoutWithApplePay(orderID: "fake-order", paymentRequest: paymentRequest) { (validatorResult, error, handler) in
                XCTAssertNil(validatorResult)
                XCTAssertEqual(error?.localizedDescription, "An internal error occured during checkout. Please contact Support.")

                XCTAssert(self.mockBTAPIClient.postedAnalyticsEvents.contains("ios.paypal-commerce-platform.apple-pay-checkout.failed"))

                expectation.fulfill()
            }
            
            let delegate = validatorClient as? PKPaymentAuthorizationViewControllerDelegate
            delegate?.paymentAuthorizationViewController?(PKPaymentAuthorizationViewController(), didAuthorizePayment: PKPayment(), handler: { _ in })
            
            waitForExpectations(timeout: 1.0, handler: nil)
        }
    }

    func testPaymentAuthorizationViewControllerDidAuthorizePayment_whenApplePayValidationFails_callsCompletionWithError() {
        if #available(iOS 11.0, *) {
            let expectation = self.expectation(description: "payment authorization delegate calls completion with error")
            
            mockPayPalAPIClient.validationError = NSError(domain: "some-domain", code: 1, userInfo: [NSLocalizedDescriptionKey: "error message"])
            mockPayPalAPIClient.validationResult = nil
            
            validatorClient?.checkoutWithApplePay(orderID: "fake-order", paymentRequest: paymentRequest) { (validatorResult, error, handler) in
                XCTAssertNil(validatorResult)
                XCTAssertEqual(error?.localizedDescription, "error message")

                XCTAssert(self.mockBTAPIClient.postedAnalyticsEvents.contains("ios.paypal-commerce-platform.apple-pay-checkout.failed"))

                expectation.fulfill()
            }
            
            let delegate = validatorClient as? PKPaymentAuthorizationViewControllerDelegate
            delegate?.paymentAuthorizationViewController?(PKPaymentAuthorizationViewController(), didAuthorizePayment: PKPayment(), handler: { _ in })
            
            waitForExpectations(timeout: 1.0, handler: nil)
        }
    }

    func testPaymentAuthorizationViewControllerDidAuthorizePayment_whenTransactionSucceeds_callsApplePayCompletionWithSuccess() {
        if #available(iOS 11.0, *) {
            let expectation = self.expectation(description: "merchant calls applePayResultHandler with true")
            mockPayPalAPIClient.validationResult = PPCValidationResult()

            validatorClient?.checkoutWithApplePay(orderID: "fake-order", paymentRequest: paymentRequest) { (_, _, handler) in
                // merchant calls handler to indicate successful transaction
                handler?(true)
            }

            let delegate = validatorClient as? PKPaymentAuthorizationViewControllerDelegate
            delegate?.paymentAuthorizationViewController?(PKPaymentAuthorizationViewController(), didAuthorizePayment: PKPayment(), handler: { authorizationResult in
                XCTAssertEqual(authorizationResult.status, .success)
                XCTAssert(self.mockBTAPIClient.postedAnalyticsEvents.contains("ios.paypal-commerce-platform.apple-pay-result-handler.true"))
                expectation.fulfill()
            })

            waitForExpectations(timeout: 1.0, handler: nil)
        }
    }

    func testPaymentAuthorizationViewControllerDidAuthorizePayment_whenTransactionFails_callsApplePayCompletionWithFailure() {
        if #available(iOS 11.0, *) {
            let expectation = self.expectation(description: "merchant calls applePayResultHandler with false")
            mockPayPalAPIClient.validationResult = PPCValidationResult()

            validatorClient?.checkoutWithApplePay(orderID: "fake-order", paymentRequest: paymentRequest) { (_, _, handler) in
                // merchant calls handler to indicate a failed transaction
                handler?(false)
            }

            let delegate = validatorClient as? PKPaymentAuthorizationViewControllerDelegate
            delegate?.paymentAuthorizationViewController?(PKPaymentAuthorizationViewController(), didAuthorizePayment: PKPayment(), handler: { authorizationResult in
                XCTAssertEqual(authorizationResult.status, .failure)
                XCTAssert(self.mockBTAPIClient.postedAnalyticsEvents.contains("ios.paypal-commerce-platform.apple-pay-result-handler.false"))
                expectation.fulfill()
            })

            waitForExpectations(timeout: 1.0, handler: nil)
        }
    }

    // MARK: - paymentAuthorizationViewControllerDidAuthorizePayment (pre iOS 11)

    func testPaymentAuthorizationViewControllerDidAuthorizePayment_callsCompletionWithValidatorResult_preiOS11() {
        let expectation = self.expectation(description: "payment authorization delegate calls completion with validator result")

        mockPayPalAPIClient.validationResult = PPCValidationResult()

        validatorClient?.checkoutWithApplePay(orderID: "fake-order", paymentRequest: paymentRequest) { (validatorResult, error, handler) in
            XCTAssertEqual(validatorResult?.orderID, "fake-order")
            XCTAssertEqual(validatorResult?.type, .applePay)
            XCTAssertNil(error)
            XCTAssertNotNil(handler)
            // TODO - test that handler is called correctly
            expectation.fulfill()
        }

        let delegate = validatorClient as? PKPaymentAuthorizationViewControllerDelegate
        delegate?.paymentAuthorizationViewController?(PKPaymentAuthorizationViewController(), didAuthorizePayment: PKPayment(), completion: { (_) in })

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testPaymentAuthorizationViewControllerDidAuthorizePayment_whenApplePayTokenizationFails_callsCompletionWithError_preiOS11() {
        let expectation = self.expectation(description: "payment authorization delegate calls completion with error")

        mockApplePayClient.applePayCardNonce = nil
        mockApplePayClient.tokenizeError = NSError(domain: "some-domain", code: 1, userInfo: [NSLocalizedDescriptionKey: "BT tokenization error"])

        validatorClient?.checkoutWithApplePay(orderID: "fake-order", paymentRequest: paymentRequest) { (validatorResult, error, handler) in
            XCTAssertNil(validatorResult)
            XCTAssertEqual(error?.localizedDescription, "An internal error occured during checkout. Please contact Support.")
            expectation.fulfill()
        }

        let delegate = validatorClient as? PKPaymentAuthorizationViewControllerDelegate
        delegate?.paymentAuthorizationViewController?(PKPaymentAuthorizationViewController(), didAuthorizePayment: PKPayment(), completion: { (_) in })

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testPaymentAuthorizationViewControllerDidAuthorizePayment_whenApplePayValidationFails_callsCompletionWithError_preiOS11() {
        let expectation = self.expectation(description: "payment authorization delegate calls completion with error")

        mockPayPalAPIClient.validationError = NSError(domain: "some-domain", code: 1, userInfo: [NSLocalizedDescriptionKey: "error message"])
        mockPayPalAPIClient.validationResult = nil

        validatorClient?.checkoutWithApplePay(orderID: "fake-order", paymentRequest: paymentRequest) { (validatorResult, error, handler) in
            XCTAssertNil(validatorResult)
            XCTAssertEqual(error?.localizedDescription, "error message")
            expectation.fulfill()
        }

        let delegate = validatorClient as? PKPaymentAuthorizationViewControllerDelegate
        delegate?.paymentAuthorizationViewController?(PKPaymentAuthorizationViewController(), didAuthorizePayment: PKPayment(), completion: { (_) in })

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testPaymentAuthorizationViewControllerDidAuthorizePayment_whenTransactionSucceeds_callsApplePayCompletionWithSuccess_preiOS11() {
        let expectation = self.expectation(description: "merchant calls applePayResultHandler with true")

        mockPayPalAPIClient.validationResult = PPCValidationResult()

        validatorClient?.checkoutWithApplePay(orderID: "fake-order", paymentRequest: paymentRequest) { (_, _, handler) in
            // merchant calls handler to indicate successful transaction
            handler?(true)
        }

        let delegate = validatorClient as? PKPaymentAuthorizationViewControllerDelegate
        delegate?.paymentAuthorizationViewController?(PKPaymentAuthorizationViewController(), didAuthorizePayment: PKPayment(), completion: { status in
            XCTAssertEqual(status, .success)
            XCTAssert(self.mockBTAPIClient.postedAnalyticsEvents.contains("ios.paypal-commerce-platform.apple-pay-result-handler.true"))
            expectation.fulfill()
        })

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testPaymentAuthorizationViewControllerDidAuthorizePayment_whenTransactionFails_callsApplePayCompletionWithFailure_preiOS11() {
        let expectation = self.expectation(description: "merchant calls applePayResultHandler with false")

        mockPayPalAPIClient.validationResult = PPCValidationResult()

        validatorClient?.checkoutWithApplePay(orderID: "fake-order", paymentRequest: paymentRequest) { (_, _, handler) in
            // merchant calls handler to indicate failed transaction
            handler?(false)
        }

        let delegate = validatorClient as? PKPaymentAuthorizationViewControllerDelegate
        delegate?.paymentAuthorizationViewController?(PKPaymentAuthorizationViewController(), didAuthorizePayment: PKPayment(), completion: { status in
            XCTAssertEqual(status, .failure)
            XCTAssert(self.mockBTAPIClient.postedAnalyticsEvents.contains("ios.paypal-commerce-platform.apple-pay-result-handler.false"))
            expectation.fulfill()
        })

        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    // MARK: - checkoutWithCard
    
    func testCheckoutWithCard_whenNoContingencyURLIsReturned_callsCompletionWithResult() {
        let expectation = self.expectation(description: "calls completion with result")
        
        mockPayPalAPIClient.validationResult = PPCValidationResult()
        
        validatorClient?.checkoutWithCard(orderID: "fake-order", card: BTCard()) { (validatorResult, error) in
            XCTAssertEqual(validatorResult?.orderID, "fake-order")
            XCTAssertEqual(validatorResult?.type, .card)
            XCTAssertNil(error)

            XCTAssert(self.mockBTAPIClient.postedAnalyticsEvents.contains("ios.paypal-commerce-platform.card-checkout.started"))
            XCTAssert(self.mockBTAPIClient.postedAnalyticsEvents.contains("ios.paypal-commerce-platform.card-checkout.succeeded"))
            XCTAssert(self.mockBTAPIClient.postedAnalyticsEvents.contains("ios.paypal-commerce-platform.card-contingency.no-challenge"))

            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testCheckoutWithCard_whenContingencyURLIsReturned_andPaymentFlowSucceeds_callsCompletionWithResult() {
        let expectation = self.expectation(description: "calls completion with result")
        
        let validateJSON = [
            "links": [
                [
                    "href": "www.contingency.com",
                    "rel": "3ds-contingency-resolution",
                    "method": "GET"
                ],
            ]
        ] as [String : Any]
        
        let validationResult = PPCValidationResult(json: BTJSON(value: validateJSON))
        mockPayPalAPIClient.validationResult = validationResult
        
        mockPaymentFlowDriver.paymentFlowResult = BTPaymentFlowResult()
        
        validatorClient?.checkoutWithCard(orderID: "fake-order", card: BTCard()) { (validatorResult, error) in
            XCTAssertEqual(validatorResult?.orderID, "fake-order")
            XCTAssertEqual(validatorResult?.type, .card)
            XCTAssertNil(error)

            XCTAssert(self.mockBTAPIClient.postedAnalyticsEvents.contains("ios.paypal-commerce-platform.card-contingency.started"))
            XCTAssert(self.mockBTAPIClient.postedAnalyticsEvents.contains("ios.paypal-commerce-platform.card-contingency.succeeded"))

            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testCheckoutWithCard_whenContingencyURLIsReturned_andPaymentFlowFails_callsCompletionWithError() {
        let expectation = self.expectation(description: "calls completion with error")
        
        let validateJSON = [
            "links": [
                [
                    "href": "www.contingency.com",
                    "rel": "3ds-contingency-resolution",
                    "method": "GET"
                ],
            ]
        ] as [String : Any]
        
        let validationResult = PPCValidationResult(json: BTJSON(value: validateJSON))
        mockPayPalAPIClient.validationResult = validationResult
        
        mockPaymentFlowDriver.paymentFlowResult = nil
        mockPaymentFlowDriver.paymentFlowError = NSError(domain: "some-domain", code: 1, userInfo: [NSLocalizedDescriptionKey: "error message"])
        
        validatorClient?.checkoutWithCard(orderID: "fake-order", card: BTCard()) { (validatorResult, error) in
            XCTAssertNil(validatorResult)
            XCTAssertEqual(error?.localizedDescription, "error message")

            XCTAssert(self.mockBTAPIClient.postedAnalyticsEvents.contains("ios.paypal-commerce-platform.card-contingency.failed"))

            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testCheckoutWithCard_whenCardTokenizationFails_callsCompletionWithError() {
        let expectation = self.expectation(description: "calls completion with error")
        
        mockCardClient.tokenizeCardError = NSError(domain: "some-domain", code: 1, userInfo: [NSLocalizedDescriptionKey: "BT Tokenization error"])
        mockCardClient.cardNonce = nil
        
        validatorClient?.checkoutWithCard(orderID: "fake-order", card: BTCard()) { (validatorResult, error) in
            XCTAssertNil(validatorResult)
            XCTAssertEqual(error?.localizedDescription, "An internal error occured during checkout. Please contact Support.")

            XCTAssert(self.mockBTAPIClient.postedAnalyticsEvents.contains("ios.paypal-commerce-platform.card-checkout.failed"))

            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testCheckoutWithCard_whenValidationFails_callsCompletionWithError() {
        let expectation = self.expectation(description: "calls completion with error")
        
        mockPayPalAPIClient.validationError = NSError(domain: "some-domain", code: 1, userInfo: [NSLocalizedDescriptionKey: "error message"])
        mockPayPalAPIClient.validationResult = nil
        
        validatorClient?.checkoutWithCard(orderID: "fake-order", card: BTCard()) { (validatorResult, error) in
            XCTAssertNil(validatorResult)
            XCTAssertEqual(error?.localizedDescription, "error message")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testCheckoutWithCard_callsPayPalDataCollector_getClientMetadataID() {
        PPCValidatorClient.setPayPalDataCollectorClass(MockPPDataCollector.self)

        let expectation = self.expectation(description: "calls PPDataCollector.clientMetadataId()")

        validatorClient?.checkoutWithCard(orderID: "fake-order", card: BTCard()) { (validatorResult, error) in
            XCTAssertTrue(MockPPDataCollector.didFetchClientMetadataID)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    // MARK: - checkoutWithPayPal
    
    func testCheckoutWithPayPal_callsCompletionWithValidatorResult() {
        let expectation = self.expectation(description: "calls completion with validator result")
                
        validatorClient?.checkoutWithPayPal(orderID: "fake-order") { (validatorResult, error) in
            XCTAssertEqual(validatorResult?.orderID, "fake-order")
            XCTAssertEqual(validatorResult?.type, .payPal)
            XCTAssertNil(error)

            XCTAssert(self.mockBTAPIClient.postedAnalyticsEvents.contains("ios.paypal-commerce-platform.paypal-checkout.started"))
            XCTAssert(self.mockBTAPIClient.postedAnalyticsEvents.contains("ios.paypal-commerce-platform.paypal-checkout.succeeded"))

            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testCheckoutWithPayPal_callsPayPalDataCollector_getClientMetadataID() {
        PPCValidatorClient.setPayPalDataCollectorClass(MockPPDataCollector.self)

        let expectation = self.expectation(description: "calls PPDataCollector.clientMetadataId()")

        validatorClient?.checkoutWithPayPal(orderID: "fake-order") { (validatorResult, error) in
            XCTAssertTrue(MockPPDataCollector.didFetchClientMetadataID)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testCheckoutWithPayPal_whenStartPaymentFlowFails_callsCompletionWithError() {
        let expectation = self.expectation(description: "calls completion with error")
        
        mockPaymentFlowDriver.paymentFlowError = NSError(domain: "some-domain", code: 1, userInfo: [NSLocalizedDescriptionKey: "error message"])
        mockPaymentFlowDriver.paymentFlowResult = nil
        
        validatorClient?.checkoutWithPayPal(orderID: "fake-order") { (validatorResult, error) in
            XCTAssertNil(validatorResult)
            XCTAssertEqual(error?.localizedDescription, "error message")

            XCTAssert(self.mockBTAPIClient.postedAnalyticsEvents.contains("ios.paypal-commerce-platform.paypal-checkout.started"))
            XCTAssert(self.mockBTAPIClient.postedAnalyticsEvents.contains("ios.paypal-commerce-platform.paypal-checkout.failed"))

            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testCheckoutWithPayPal_paymentFlowRequest_containsSandboxCheckoutURL() {
        let expectation = self.expectation(description: "calls completion")

        mockPaymentFlowDriver.onStartPaymentFlow = { (request: BTPaymentFlowRequest) -> Void in
            XCTAssertEqual((request as! PPCPayPalCheckoutRequest).checkoutURL, URL(string: "https://www.sandbox.paypal.com/checkoutnow?token=fake-order"))
        }

        validatorClient?.checkoutWithPayPal(orderID: "fake-order") { (validatorResult, error) in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testCheckoutWithPayPal_paymentFlowRequest_containsStagingCheckoutURL() {
        let expectation = self.expectation(description: "calls completion")

        let uatParams: [String : Any] = [
          "iss": "https://api.msmaster.qa.paypal.com",
          "external_ids": [
            "Braintree:merchant-id"
          ]
        ]

        validatorClient = PPCValidatorClient(accessToken: PayPalUATTestHelper.encodeUAT(uatParams))
        mockPaymentFlowDriver = MockPaymentFlowDriver(apiClient: mockBTAPIClient)
        validatorClient?.paymentFlowDriver = mockPaymentFlowDriver

        mockPaymentFlowDriver.onStartPaymentFlow = { (request: BTPaymentFlowRequest) -> Void in
            XCTAssertEqual((request as! PPCPayPalCheckoutRequest).checkoutURL, URL(string: "https://www.msmaster.qa.paypal.com/checkoutnow?token=fake-order"))
        }

        validatorClient?.checkoutWithPayPal(orderID: "fake-order") { (validatorResult, error) in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testCheckoutWithPayPal_paymentFlowRequest_containsProductionCheckoutURL() {
        let expectation = self.expectation(description: "calls completion")

        let uatParams: [String : Any] = [
            "iss": "https://api.paypal.com",
            "external_ids": [
                "Braintree:merchant-id"
            ]
        ]

        validatorClient = PPCValidatorClient(accessToken: PayPalUATTestHelper.encodeUAT(uatParams))
        mockPaymentFlowDriver = MockPaymentFlowDriver(apiClient: mockBTAPIClient)
        validatorClient?.paymentFlowDriver = mockPaymentFlowDriver

        mockPaymentFlowDriver.onStartPaymentFlow = { (request: BTPaymentFlowRequest) -> Void in
            XCTAssertEqual((request as! PPCPayPalCheckoutRequest).checkoutURL, URL(string: "https://www.paypal.com/checkoutnow?token=fake-order"))
        }

        validatorClient?.checkoutWithPayPal(orderID: "fake-order") { (validatorResult, error) in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0, handler: nil)
    }
}
