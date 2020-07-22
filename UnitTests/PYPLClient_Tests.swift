import XCTest

class PYPLClient_Tests: XCTestCase {

    let idTokenParams: [String : Any] = [
      "iss": "https://api.sandbox.paypal.com",
      "external_id": [
        "Braintree:merchant-id"
      ]
    ]
    
    var idTokenString: String!
    
    var payPalClient: PYPLClient!
    let paymentRequest = PKPaymentRequest()

    var mockBTAPIClient: MockBTAPIClient!
    let mockPayPalAPIClient = MockPayPalAPIClient()
    var mockApplePayClient: MockApplePayClient!
    var mockCardClient: MockCardClient!
    var mockPaymentFlowDriver: MockPaymentFlowDriver!
    let mockViewControllerPresentingDelegate = MockViewControllerPresentingDelegate()

    override func setUp() {
        idTokenString = PayPalUATTestHelper.encodeUAT(idTokenParams)
        
        payPalClient = PYPLClient(idToken: idTokenString)
        mockBTAPIClient = MockBTAPIClient(authorization: idTokenString)
        
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
        
        payPalClient?.applePayClient = mockApplePayClient
        payPalClient?.payPalAPIClient = mockPayPalAPIClient
        payPalClient?.cardClient = mockCardClient
        payPalClient?.braintreeAPIClient = mockBTAPIClient
        payPalClient?.paymentFlowDriver = mockPaymentFlowDriver
        payPalClient?.presentingDelegate = mockViewControllerPresentingDelegate
        
        paymentRequest.paymentSummaryItems = [PKPaymentSummaryItem(label: "item", amount: 1.00)]
        paymentRequest.merchantCapabilities = PKMerchantCapability.capabilityCredit
    }

    override func tearDown() {
        mockBTAPIClient.postedAnalyticsEvents.removeAll()
    }

    // MARK: - initWithAccessToken

    func testClientInitialization_withUAT_initializesAllProperties() {
        let payPalClient = PYPLClient(idToken: idTokenString)
        XCTAssertNotNil(payPalClient)
        XCTAssertNotNil(payPalClient?.payPalAPIClient)
        XCTAssertNotNil(payPalClient?.braintreeAPIClient)
        XCTAssertNotNil(payPalClient?.paymentFlowDriver)
        XCTAssertNotNil(payPalClient?.cardClient)
        XCTAssertNotNil(payPalClient?.applePayClient)
        XCTAssertNotNil(payPalClient?.payPalIDToken)
    }

    func testClientInitialization_withInvalidUAT_returnsNil() {
        let payPalClient = PYPLClient(idToken: "header.invalid_paypal_id_token_body.signature")
        XCTAssertNil(payPalClient)
    }
    
    // MARK: - checkoutWithApplePay
    
    func testCheckoutWithApplePay_whenDefaultPaymentRequestIsAvailable_requestsPresentationOfViewController() {
        let expectation = self.expectation(description: "passes Apple Pay view controller to merchant")
        
        mockViewControllerPresentingDelegate.onPaymentDriverRequestsPresentation = { driver, viewController in
            XCTAssertEqual(driver as? PYPLClient, self.payPalClient)
            XCTAssertNotNil(viewController)
            XCTAssertTrue(viewController is PKPaymentAuthorizationViewController)
            expectation.fulfill()
        }

        payPalClient?.checkoutWithApplePay(orderID: "my-order-id", paymentRequest: paymentRequest) { (_, _, _) in
            // not called
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testCheckoutWithApplePay_whenDefaultPaymentRequestIsNotAvailable_returnsError() {
        self.mockApplePayClient.paymentRequestError = NSError(domain: "error", code: 0, userInfo: [NSLocalizedDescriptionKey: "error message"])
        self.mockApplePayClient.paymentRequest = nil

        let expectation = self.expectation(description: "returns Apple Pay error to merchant")

        payPalClient?.checkoutWithApplePay(orderID: "my-order-id", paymentRequest: PKPaymentRequest()) { (checkoutResult, error, handler) in
            XCTAssertEqual(error?.localizedDescription, "error message")
            XCTAssertNil(checkoutResult)
            XCTAssertNil(handler)

            XCTAssert(self.mockBTAPIClient.postedAnalyticsEvents.contains("ios.paypal-sdk.apple-pay-payment-request.failed"))
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testCheckoutWithApplePay_callsPayPalDataCollector_getClientMetadataID() {
        PYPLClient.setPayPalDataCollectorClass(MockPPDataCollector.self)

        let expectation = self.expectation(description: "calls PPDataCollector.clientMetadataId()")

        mockViewControllerPresentingDelegate.onPaymentDriverRequestsPresentation = { _, _ in
            XCTAssertTrue(MockPPDataCollector.didFetchClientMetadataID)
            expectation.fulfill()
        }

        payPalClient?.checkoutWithApplePay(orderID: "fake-order", paymentRequest: paymentRequest) { (_, _, _) in }

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    // MARK: - paymentAuthorizationViewControllerDidAuthorizePayment (iOS 11+)

    func testPaymentAuthorizationViewControllerDidAuthorizePayment_callsCompletionWithCheckoutResult() {
        if #available(iOS 11.0, *) {
            let expectation = self.expectation(description: "payment authorization delegate calls completion with checkout result")
            
            mockPayPalAPIClient.validationResult = PYPLValidationResult()
            
            payPalClient?.checkoutWithApplePay(orderID: "fake-order", paymentRequest: paymentRequest) { (checkoutResult, error, handler) in
                XCTAssertEqual(checkoutResult?.orderID, "fake-order")
                XCTAssertNil(error)
                XCTAssertNotNil(handler)
                
                XCTAssert(self.mockBTAPIClient.postedAnalyticsEvents.contains("ios.paypal-sdk.apple-pay-checkout.started"))
                XCTAssert(self.mockBTAPIClient.postedAnalyticsEvents.contains("ios.paypal-sdk.apple-pay-checkout.succeeded"))
                expectation.fulfill()
            }

            let delegate = payPalClient as? PKPaymentAuthorizationViewControllerDelegate
            delegate?.paymentAuthorizationViewController?(PKPaymentAuthorizationViewController(), didAuthorizePayment: PKPayment(), handler: { _ in })
            
            waitForExpectations(timeout: 1.0, handler: nil)
        }
    }

    func testDidAuthorizePayment_withPKPaymentParams_callsCompletionWithResultParamsIncluded() {
        if #available(iOS 11.0, *) {
            let expectation = self.expectation(description: "payment authorization delegate calls completion with apple pay checkout result")

            // Create PKPayment
            var shippingName = PersonNameComponents()
            shippingName.givenName = "Alicia"

            let address = CNMutablePostalAddress.init()
            address.city = "Berlin"

            var billingName = PersonNameComponents()
            billingName.givenName = "Lady"
            billingName.familyName = "Gaga"

            let shippingContact = PKContact()
            shippingContact.name = shippingName
            shippingContact.postalAddress = address

            let billingContact = PKContact()
            billingContact.name = billingName
            billingContact.postalAddress = address

            let shippingMethod = PKShippingMethod(label: "Sneakers", amount: 99.99)

            let payment = MockPKPayment(shippingContact: shippingContact, billingContact: billingContact, shippingMethod: shippingMethod)

            mockPayPalAPIClient.validationResult = PYPLValidationResult()

            payPalClient?.checkoutWithApplePay(orderID: "fake-order", paymentRequest: paymentRequest) { (result, error, handler) in
                XCTAssertEqual(result?.orderID, "fake-order")
                XCTAssertEqual(result?.billingContact?.name?.givenName, "Lady")
                XCTAssertEqual(result?.billingContact?.name?.familyName, "Gaga")
                XCTAssertEqual(result?.shippingContact?.name?.givenName, "Alicia")
                XCTAssertEqual(result?.shippingContact?.postalAddress?.city, "Berlin")
                XCTAssertEqual(result?.billingContact?.postalAddress?.city, "Berlin")
                XCTAssertEqual(result?.shippingMethod?.label, "Sneakers")
                XCTAssertEqual(result?.shippingMethod?.amount, 99.99)

                expectation.fulfill()
            }

            let delegate = payPalClient as? PKPaymentAuthorizationViewControllerDelegate
            delegate?.paymentAuthorizationViewController?(PKPaymentAuthorizationViewController(), didAuthorizePayment: payment, handler: { _ in })

            waitForExpectations(timeout: 1.0, handler: nil)
        }
    }

    func testPaymentAuthorizationViewControllerDidAuthorizePayment_whenApplePayTokenizationFails_callsCompletionWithError() {
        if #available(iOS 11.0, *) {
            let expectation = self.expectation(description: "payment authorization delegate calls completion with error")
            
            mockApplePayClient.applePayCardNonce = nil
            mockApplePayClient.tokenizeError = NSError(domain: "some-domain", code: 1, userInfo: [NSLocalizedDescriptionKey: "BT tokenization error"])
            
            payPalClient?.checkoutWithApplePay(orderID: "fake-order", paymentRequest: paymentRequest) { (checkoutResult, error, handler) in
                XCTAssertNil(checkoutResult)
                XCTAssertEqual(error?.localizedDescription, "An internal error occured during checkout. Please contact Support.")

                XCTAssert(self.mockBTAPIClient.postedAnalyticsEvents.contains("ios.paypal-sdk.apple-pay-checkout.failed"))

                expectation.fulfill()
            }
            
            let delegate = payPalClient as? PKPaymentAuthorizationViewControllerDelegate
            delegate?.paymentAuthorizationViewController?(PKPaymentAuthorizationViewController(), didAuthorizePayment: PKPayment(), handler: { _ in })
            
            waitForExpectations(timeout: 1.0, handler: nil)
        }
    }

    func testPaymentAuthorizationViewControllerDidAuthorizePayment_whenApplePayValidationFails_callsCompletionWithError() {
        if #available(iOS 11.0, *) {
            let expectation = self.expectation(description: "payment authorization delegate calls completion with error")
            
            mockPayPalAPIClient.validationError = NSError(domain: "some-domain", code: 1, userInfo: [NSLocalizedDescriptionKey: "error message"])
            mockPayPalAPIClient.validationResult = nil
            
            payPalClient?.checkoutWithApplePay(orderID: "fake-order", paymentRequest: paymentRequest) { (checkoutResult, error, handler) in
                XCTAssertNil(checkoutResult)
                XCTAssertEqual(error?.localizedDescription, "error message")

                XCTAssert(self.mockBTAPIClient.postedAnalyticsEvents.contains("ios.paypal-sdk.apple-pay-checkout.failed"))

                expectation.fulfill()
            }
            
            let delegate = payPalClient as? PKPaymentAuthorizationViewControllerDelegate
            delegate?.paymentAuthorizationViewController?(PKPaymentAuthorizationViewController(), didAuthorizePayment: PKPayment(), handler: { _ in })
            
            waitForExpectations(timeout: 1.0, handler: nil)
        }
    }

    func testPaymentAuthorizationViewControllerDidAuthorizePayment_whenTransactionSucceeds_callsApplePayCompletionWithSuccess() {
        if #available(iOS 11.0, *) {
            let expectation = self.expectation(description: "merchant calls applePayResultHandler with true")
            mockPayPalAPIClient.validationResult = PYPLValidationResult()

            payPalClient?.checkoutWithApplePay(orderID: "fake-order", paymentRequest: paymentRequest) { (_, _, handler) in
                // merchant calls handler to indicate successful transaction
                handler?(true)
            }

            let delegate = payPalClient as? PKPaymentAuthorizationViewControllerDelegate
            delegate?.paymentAuthorizationViewController?(PKPaymentAuthorizationViewController(), didAuthorizePayment: PKPayment(), handler: { authorizationResult in
                XCTAssertEqual(authorizationResult.status, .success)
                XCTAssert(self.mockBTAPIClient.postedAnalyticsEvents.contains("ios.paypal-sdk.apple-pay-result-handler.true"))
                expectation.fulfill()
            })

            waitForExpectations(timeout: 1.0, handler: nil)
        }
    }

    func testPaymentAuthorizationViewControllerDidAuthorizePayment_whenTransactionFails_callsApplePayCompletionWithFailure() {
        if #available(iOS 11.0, *) {
            let expectation = self.expectation(description: "merchant calls applePayResultHandler with false")
            mockPayPalAPIClient.validationResult = PYPLValidationResult()

            payPalClient?.checkoutWithApplePay(orderID: "fake-order", paymentRequest: paymentRequest) { (_, _, handler) in
                // merchant calls handler to indicate a failed transaction
                handler?(false)
            }

            let delegate = payPalClient as? PKPaymentAuthorizationViewControllerDelegate
            delegate?.paymentAuthorizationViewController?(PKPaymentAuthorizationViewController(), didAuthorizePayment: PKPayment(), handler: { authorizationResult in
                XCTAssertEqual(authorizationResult.status, .failure)
                XCTAssert(self.mockBTAPIClient.postedAnalyticsEvents.contains("ios.paypal-sdk.apple-pay-result-handler.false"))
                expectation.fulfill()
            })

            waitForExpectations(timeout: 1.0, handler: nil)
        }
    }

    // MARK: - paymentAuthorizationViewControllerDidAuthorizePayment (pre iOS 11)

    func testPaymentAuthorizationViewControllerDidAuthorizePayment_callsCompletionWithCheckoutResult_preiOS11() {
        let expectation = self.expectation(description: "payment authorization delegate calls completion with checkout result")

        mockPayPalAPIClient.validationResult = PYPLValidationResult()

        payPalClient?.checkoutWithApplePay(orderID: "fake-order", paymentRequest: paymentRequest) { (checkoutResult, error, handler) in
            XCTAssertEqual(checkoutResult?.orderID, "fake-order")
            XCTAssertNil(error)
            XCTAssertNotNil(handler)
            // TODO - test that handler is called correctly
            expectation.fulfill()
        }

        let delegate = payPalClient as? PKPaymentAuthorizationViewControllerDelegate
        delegate?.paymentAuthorizationViewController?(PKPaymentAuthorizationViewController(), didAuthorizePayment: PKPayment(), completion: { (_) in })

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testPaymentAuthorizationViewControllerDidAuthorizePayment_whenApplePayTokenizationFails_callsCompletionWithError_preiOS11() {
        let expectation = self.expectation(description: "payment authorization delegate calls completion with error")

        mockApplePayClient.applePayCardNonce = nil
        mockApplePayClient.tokenizeError = NSError(domain: "some-domain", code: 1, userInfo: [NSLocalizedDescriptionKey: "BT tokenization error"])

        payPalClient?.checkoutWithApplePay(orderID: "fake-order", paymentRequest: paymentRequest) { (checkoutResult, error, handler) in
            XCTAssertNil(checkoutResult)
            XCTAssertEqual(error?.localizedDescription, "An internal error occured during checkout. Please contact Support.")
            expectation.fulfill()
        }

        let delegate = payPalClient as? PKPaymentAuthorizationViewControllerDelegate
        delegate?.paymentAuthorizationViewController?(PKPaymentAuthorizationViewController(), didAuthorizePayment: PKPayment(), completion: { (_) in })

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testPaymentAuthorizationViewControllerDidAuthorizePayment_whenApplePayValidationFails_callsCompletionWithError_preiOS11() {
        let expectation = self.expectation(description: "payment authorization delegate calls completion with error")

        mockPayPalAPIClient.validationError = NSError(domain: "some-domain", code: 1, userInfo: [NSLocalizedDescriptionKey: "error message"])
        mockPayPalAPIClient.validationResult = nil

        payPalClient?.checkoutWithApplePay(orderID: "fake-order", paymentRequest: paymentRequest) { (checkoutResult, error, handler) in
            XCTAssertNil(checkoutResult)
            XCTAssertEqual(error?.localizedDescription, "error message")
            expectation.fulfill()
        }

        let delegate = payPalClient as? PKPaymentAuthorizationViewControllerDelegate
        delegate?.paymentAuthorizationViewController?(PKPaymentAuthorizationViewController(), didAuthorizePayment: PKPayment(), completion: { (_) in })

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testPaymentAuthorizationViewControllerDidAuthorizePayment_whenTransactionSucceeds_callsApplePayCompletionWithSuccess_preiOS11() {
        let expectation = self.expectation(description: "merchant calls applePayResultHandler with true")

        mockPayPalAPIClient.validationResult = PYPLValidationResult()

        payPalClient?.checkoutWithApplePay(orderID: "fake-order", paymentRequest: paymentRequest) { (_, _, handler) in
            // merchant calls handler to indicate successful transaction
            handler?(true)
        }

        let delegate = payPalClient as? PKPaymentAuthorizationViewControllerDelegate
        delegate?.paymentAuthorizationViewController?(PKPaymentAuthorizationViewController(), didAuthorizePayment: PKPayment(), completion: { status in
            XCTAssertEqual(status, .success)
            XCTAssert(self.mockBTAPIClient.postedAnalyticsEvents.contains("ios.paypal-sdk.apple-pay-result-handler.true"))
            expectation.fulfill()
        })

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testPaymentAuthorizationViewControllerDidAuthorizePayment_whenTransactionFails_callsApplePayCompletionWithFailure_preiOS11() {
        let expectation = self.expectation(description: "merchant calls applePayResultHandler with false")

        mockPayPalAPIClient.validationResult = PYPLValidationResult()

        payPalClient?.checkoutWithApplePay(orderID: "fake-order", paymentRequest: paymentRequest) { (_, _, handler) in
            // merchant calls handler to indicate failed transaction
            handler?(false)
        }

        let delegate = payPalClient as? PKPaymentAuthorizationViewControllerDelegate
        delegate?.paymentAuthorizationViewController?(PKPaymentAuthorizationViewController(), didAuthorizePayment: PKPayment(), completion: { status in
            XCTAssertEqual(status, .failure)
            XCTAssert(self.mockBTAPIClient.postedAnalyticsEvents.contains("ios.paypal-sdk.apple-pay-result-handler.false"))
            expectation.fulfill()
        })

        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    // MARK: - checkoutWithCard
    
    func testCheckoutWithCard_whenNoContingencyURLIsReturned_callsCompletionWithResult() {
        let expectation = self.expectation(description: "calls completion with result")
        
        mockPayPalAPIClient.validationResult = PYPLValidationResult()
        
        payPalClient?.checkoutWithCard(orderID: "fake-order", card: BTCard()) { (checkoutResult, error) in
            XCTAssertEqual(checkoutResult?.orderID, "fake-order")
            XCTAssertNil(error)

            XCTAssert(self.mockBTAPIClient.postedAnalyticsEvents.contains("ios.paypal-sdk.card-checkout.started"))
            XCTAssert(self.mockBTAPIClient.postedAnalyticsEvents.contains("ios.paypal-sdk.card-checkout.succeeded"))
            XCTAssert(self.mockBTAPIClient.postedAnalyticsEvents.contains("ios.paypal-sdk.card-contingency.no-challenge"))

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
        
        let validationResult = PYPLValidationResult(json: BTJSON(value: validateJSON))
        mockPayPalAPIClient.validationResult = validationResult
        
        mockPaymentFlowDriver.paymentFlowResult = BTPaymentFlowResult()
        
        payPalClient?.checkoutWithCard(orderID: "fake-order", card: BTCard()) { (checkoutResult, error) in
            XCTAssertEqual(checkoutResult?.orderID, "fake-order")
            XCTAssertNil(error)

            XCTAssert(self.mockBTAPIClient.postedAnalyticsEvents.contains("ios.paypal-sdk.card-contingency.started"))
            XCTAssert(self.mockBTAPIClient.postedAnalyticsEvents.contains("ios.paypal-sdk.card-contingency.succeeded"))

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
        
        let validationResult = PYPLValidationResult(json: BTJSON(value: validateJSON))
        mockPayPalAPIClient.validationResult = validationResult
        
        mockPaymentFlowDriver.paymentFlowResult = nil
        mockPaymentFlowDriver.paymentFlowError = NSError(domain: "some-domain", code: 1, userInfo: [NSLocalizedDescriptionKey: "error message"])
        
        payPalClient?.checkoutWithCard(orderID: "fake-order", card: BTCard()) { (checkoutResult, error) in
            XCTAssertNil(checkoutResult)
            XCTAssertEqual(error?.localizedDescription, "error message")

            XCTAssert(self.mockBTAPIClient.postedAnalyticsEvents.contains("ios.paypal-sdk.card-contingency.failed"))

            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testCheckoutWithCard_whenCardTokenizationFails_callsCompletionWithError() {
        let expectation = self.expectation(description: "calls completion with error")
        
        mockCardClient.tokenizeCardError = NSError(domain: "some-domain", code: 1, userInfo: [NSLocalizedDescriptionKey: "BT Tokenization error"])
        mockCardClient.cardNonce = nil
        
        payPalClient?.checkoutWithCard(orderID: "fake-order", card: BTCard()) { (checkoutResult, error) in
            XCTAssertNil(checkoutResult)
            XCTAssertEqual(error?.localizedDescription, "An internal error occured during checkout. Please contact Support.")

            XCTAssert(self.mockBTAPIClient.postedAnalyticsEvents.contains("ios.paypal-sdk.card-checkout.failed"))

            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testCheckoutWithCard_whenValidationFails_callsCompletionWithError() {
        let expectation = self.expectation(description: "calls completion with error")
        
        mockPayPalAPIClient.validationError = NSError(domain: "some-domain", code: 1, userInfo: [NSLocalizedDescriptionKey: "error message"])
        mockPayPalAPIClient.validationResult = nil
        
        payPalClient?.checkoutWithCard(orderID: "fake-order", card: BTCard()) { (checkoutResult, error) in
            XCTAssertNil(checkoutResult)
            XCTAssertEqual(error?.localizedDescription, "error message")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testCheckoutWithCard_callsPayPalDataCollector_getClientMetadataID() {
        PYPLClient.setPayPalDataCollectorClass(MockPPDataCollector.self)

        let expectation = self.expectation(description: "calls PPDataCollector.clientMetadataId()")

        payPalClient?.checkoutWithCard(orderID: "fake-order", card: BTCard()) { (checkoutResult, error) in
            XCTAssertTrue(MockPPDataCollector.didFetchClientMetadataID)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    // MARK: - checkoutWithPayPal
    
    func testCheckoutWithPayPal_callsCompletionWithCheckoutResult() {
        let expectation = self.expectation(description: "calls completion with checkout result")
                
        payPalClient?.checkoutWithPayPal(orderID: "fake-order") { (checkoutResult, error) in
            XCTAssertEqual(checkoutResult?.orderID, "fake-order")
            XCTAssertNil(error)

            XCTAssert(self.mockBTAPIClient.postedAnalyticsEvents.contains("ios.paypal-sdk.paypal-checkout.started"))
            XCTAssert(self.mockBTAPIClient.postedAnalyticsEvents.contains("ios.paypal-sdk.paypal-checkout.succeeded"))

            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testCheckoutWithPayPal_callsPayPalDataCollector_getClientMetadataID() {
        PYPLClient.setPayPalDataCollectorClass(MockPPDataCollector.self)

        let expectation = self.expectation(description: "calls PPDataCollector.clientMetadataId()")

        payPalClient?.checkoutWithPayPal(orderID: "fake-order") { (checkoutResult, error) in
            XCTAssertTrue(MockPPDataCollector.didFetchClientMetadataID)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testCheckoutWithPayPal_whenStartPaymentFlowFails_callsCompletionWithError() {
        let expectation = self.expectation(description: "calls completion with error")
        
        mockPaymentFlowDriver.paymentFlowError = NSError(domain: "some-domain", code: 1, userInfo: [NSLocalizedDescriptionKey: "error message"])
        mockPaymentFlowDriver.paymentFlowResult = nil
        
        payPalClient?.checkoutWithPayPal(orderID: "fake-order") { (checkoutResult, error) in
            XCTAssertNil(checkoutResult)
            XCTAssertEqual(error?.localizedDescription, "error message")

            XCTAssert(self.mockBTAPIClient.postedAnalyticsEvents.contains("ios.paypal-sdk.paypal-checkout.started"))
            XCTAssert(self.mockBTAPIClient.postedAnalyticsEvents.contains("ios.paypal-sdk.paypal-checkout.failed"))

            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testCheckoutWithPayPal_paymentFlowRequest_containsSandboxCheckoutURL() {
        let expectation = self.expectation(description: "calls completion")

        mockPaymentFlowDriver.onStartPaymentFlow = { (request: BTPaymentFlowRequest) -> Void in
            XCTAssertEqual((request as! PYPLPayPalPaymentFlowRequest).checkoutURL, URL(string: "https://www.sandbox.paypal.com/checkoutnow?token=fake-order"))
        }

        payPalClient?.checkoutWithPayPal(orderID: "fake-order") { (checkoutResult, error) in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testCheckoutWithPayPal_paymentFlowRequest_containsStagingCheckoutURL() {
        let expectation = self.expectation(description: "calls completion")

        let idTokenParams: [String : Any] = [
          "iss": "https://api.msmaster.qa.paypal.com",
          "external_id": [
            "Braintree:merchant-id"
          ]
        ]

        payPalClient = PYPLClient(idToken: PayPalUATTestHelper.encodeUAT(idTokenParams))
        mockPaymentFlowDriver = MockPaymentFlowDriver(apiClient: mockBTAPIClient)
        payPalClient?.paymentFlowDriver = mockPaymentFlowDriver

        mockPaymentFlowDriver.onStartPaymentFlow = { (request: BTPaymentFlowRequest) -> Void in
            XCTAssertEqual((request as! PYPLPayPalPaymentFlowRequest).checkoutURL, URL(string: "https://www.msmaster.qa.paypal.com/checkoutnow?token=fake-order"))
        }

        payPalClient?.checkoutWithPayPal(orderID: "fake-order") { (checkoutResult, error) in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testCheckoutWithPayPal_paymentFlowRequest_containsProductionCheckoutURL() {
        let expectation = self.expectation(description: "calls completion")

        let idTokenParams: [String : Any] = [
            "iss": "https://api.paypal.com",
            "external_id": [
                "Braintree:merchant-id"
            ]
        ]

        payPalClient = PYPLClient(idToken: PayPalUATTestHelper.encodeUAT(idTokenParams))
        mockPaymentFlowDriver = MockPaymentFlowDriver(apiClient: mockBTAPIClient)
        payPalClient?.paymentFlowDriver = mockPaymentFlowDriver

        mockPaymentFlowDriver.onStartPaymentFlow = { (request: BTPaymentFlowRequest) -> Void in
            XCTAssertEqual((request as! PYPLPayPalPaymentFlowRequest).checkoutURL, URL(string: "https://www.paypal.com/checkoutnow?token=fake-order"))
        }

        payPalClient?.checkoutWithPayPal(orderID: "fake-order") { (checkoutResult, error) in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0, handler: nil)
    }
}
