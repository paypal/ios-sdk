import XCTest

class PPCValidationResult_Tests: XCTestCase {

    func testValidationResult_initializes_withoutContingencyURL() {
        let result = PPCValidationResult(json: BTJSON(withJSONFile: "paypal-validation-response-without-contingency")!)
        XCTAssertNil(result.contingencyURL)
    }

    func testValidationResult_initializesAllProperties_withContingencyURL() {
        let result = PPCValidationResult(json: BTJSON(withJSONFile: "paypal-validation-response-with-contingency")!)

        XCTAssertEqual(result.contingencyURL, URL(string: "www.contingency.com"))
        XCTAssertEqual(result.issueType, "CONTINGENCY")
        XCTAssertEqual(result.message, "The requested action could not be performed, semantically incorrect, or failed business validation.")
    }

    func testValidationResult_initializesSomeProperties_withExpiredCardResult() {
        let result = PPCValidationResult(json: BTJSON(withJSONFile: "paypal-validation-response-card-expired")!)

        XCTAssertEqual(result.contingencyURL, nil)
        XCTAssertEqual(result.issueType, "CARD_EXPIRED")
        XCTAssertEqual(result.message, "The requested action could not be performed, semantically incorrect, or failed business validation.")
    }

    func testValidationResult_initializesSomeProperties_withInvalidToken() {
        let result = PPCValidationResult(json: BTJSON(withJSONFile: "paypal-validation-response-invalid-token")!)

        XCTAssertEqual(result.contingencyURL, nil)
        XCTAssertEqual(result.issueType, "")
        XCTAssertEqual(result.message, "Token signature verification failed")
    }
}
