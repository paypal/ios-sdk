import Foundation
import XCTest

// NOTE: - These integration tests rely on https://ppcp-sample-merchant-sand.herokuapp.com sample server
class PPCValidatorClient_IntegrationTests: XCTestCase {

    // MARK: - Properties

    let payPalAppSwitchSuccessURL = URL(string: IntegrationTestsConstants.sandbox_paypal_app_switch_url)
    var validatorClient: PPCValidatorClient!
    var orderID: String!

    override func setUp() {
        super.setUp()

        // STEP 1 - Fetch UAT
        let expectUAT = self.expectation(description: "Fetch Universal Access Token from PPCP sample server")
        IntegrationTests_MerchantAPI.sharedService.generateUAT { (uat, error) in
            guard let uat = uat, error == nil else {
                XCTFail() // without a fresh UAT, integration tests cannot pass
                return
            }

            self.validatorClient = PPCValidatorClient(accessToken: uat)
            expectUAT.fulfill()
        }

        // STEP 2 - Fetch orderID
        let expectOrderID = self.expectation(description: "Fetch orderID from PPCP sample server")
        IntegrationTests_MerchantAPI.sharedService.generateOrderID { (orderID, error) in
            guard let orderID = orderID, error == nil else {
                XCTFail() // without a fresh orderID, the integration tests cannot pass
                return
            }

            self.orderID = orderID
            expectOrderID.fulfill()
        }

        waitForExpectations(timeout: 20.0, handler: nil)
    }

    // MARK: - Tests

    func testCheckoutWithCard_returnsSuccessResult() {
        let expectation = self.expectation(description: "Checkout with Card Complete")
        validatorClient.checkoutWithCard(orderID: self.orderID, card: validCard(), completion: { (validatorResult, error) in
            if ((error) != nil) {
                XCTFail()
            }

            XCTAssertEqual(validatorResult?.orderID, self.orderID)
            XCTAssertEqual(validatorResult?.type, .card)
            expectation.fulfill()
        })

        waitForExpectations(timeout: 15.0, handler: nil)
    }

    func testCheckoutWithPayPal_returnsSuccessResult() {
        BTAppSwitch.sharedInstance().returnURLScheme = "com.braintreepayments.Demo.payments"

        let expectation = self.expectation(description: "Checkout with PayPal Complete")
        validatorClient.checkoutWithPayPal(orderID: self.orderID, completion: { (validatorResult, error) in
            if ((error) != nil) {
                XCTFail()
            }

            XCTAssertEqual(validatorResult?.orderID, self.orderID)
            XCTAssertEqual(validatorResult?.type, .payPal)
            expectation.fulfill()
        })

        BTPaymentFlowDriver.handleAppSwitchReturn(payPalAppSwitchSuccessURL!)

        waitForExpectations(timeout: 13.0, handler: nil)
    }

    func testCheckoutWithApplePay_returnsSuccessResult() {
        let expectation = self.expectation(description: "Checkout with ApplePay Complete")
        validatorClient?.checkoutWithApplePay(orderID: self.orderID, paymentRequest: validPKPaymentRequest(), completion: { (validatorResult, error, applePayResultHandler) in
                if ((error) != nil) {
                    XCTFail()
                }

                XCTAssertEqual(validatorResult?.orderID, self.orderID)
                XCTAssertEqual(validatorResult?.type, .applePay)
                XCTAssertNotNil(applePayResultHandler)
                expectation.fulfill()
        })

        let delegate = validatorClient as? PKPaymentAuthorizationViewControllerDelegate
        delegate?.paymentAuthorizationViewController?(PKPaymentAuthorizationViewController(), didAuthorizePayment: PKPayment(), completion: { (_) in })

        waitForExpectations(timeout: 10.0, handler: nil)

    }

    // MARK: - Helpers

    func validCard() -> BTCard {
        return BTCard.init(number: "4111111111111111", expirationMonth: "01", expirationYear: "2022", cvv: "123")
    }

    func validPKPaymentRequest() -> PKPaymentRequest {
        let paymentRequest = PKPaymentRequest()

        paymentRequest.merchantCapabilities = .capability3DS
        paymentRequest.paymentSummaryItems = [
            PKPaymentSummaryItem(label: "Sock", amount: NSDecimalNumber(string: "10")),
            PKPaymentSummaryItem(label: "Demo", amount: NSDecimalNumber(string: "10")),
        ]

        return paymentRequest
    }

}
