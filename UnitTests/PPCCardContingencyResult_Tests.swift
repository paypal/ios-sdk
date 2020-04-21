import XCTest

class PPCCardContingencyResult_Tests: XCTestCase {

    func testPayPalCardContingencyResult_initializesProperties_withSuccessResultURL() {
        let resultURL = URL.init(string: "scheme://x-callback-url/braintree/paypal-validator?state=abc&code=def")!
        let contingencyResult = PPCCardContingencyResult.init(url: resultURL)

        XCTAssertEqual(contingencyResult.state, "abc")
        XCTAssertEqual(contingencyResult.code, "def")
        XCTAssertNil(contingencyResult.error)
        XCTAssertNil(contingencyResult.errorDescription)
    }

    func testPayPalCardContingencyResult_initializesProperties_withFailureResultURL() {
        let resultURL = URL.init(string: "scheme://x-callback-url/braintree/paypal-validator?state=abc&error=def&error_description=ghi")!
        let contingencyResult = PPCCardContingencyResult.init(url: resultURL)

        XCTAssertEqual(contingencyResult.state, "abc")
        XCTAssertEqual(contingencyResult.error!, "def")
        XCTAssertEqual(contingencyResult.errorDescription!, "ghi")
    }
}
