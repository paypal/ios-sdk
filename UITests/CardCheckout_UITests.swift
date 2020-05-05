import XCTest

// NOTE: These tests fetch UAT and orderID from the sample merchant server https://ppcp-sample-merchant-sand.herokuapp.com

class CardCheckout_UITests: XCTestCase {
    var app: XCUIApplication!
    
    func testCapturePayment() {
        app = XCUIApplication()
        app.launchArguments.append("-Capture")
        app.launch()

        // wait for PP UAT
        let uatExistsPredicate = NSPredicate(format: "label LIKE 'Fetched UAT:*'")
        waitForElementToAppear(app.staticTexts.containing(uatExistsPredicate).element(boundBy: 0))

        // tap Create Order button
        app.buttons["Create Order"].tap()

        // wait for Order ID
        let orderExistsPredicate = NSPredicate(format: "label LIKE 'Order ID:*'")
        waitForElementToAppear(app.staticTexts.containing(orderExistsPredicate).element(boundBy: 0))

        // fill out card fields
        let cardNumberTextField = app.textFields["Card Number"]
        cardNumberTextField.tap()
        cardNumberTextField.typeText("4000000000000051")

        let expiryTextField = app.textFields["MM/YY"]
        expiryTextField.tap()
        expiryTextField.typeText("01/22")

        let cvvTextField = app.textFields["CVV"]
        cvvTextField.tap()
        cvvTextField.typeText("123")

        // tap Submit
        app.buttons["Submit"].tap()
        let checkoutCompletePredicate = NSPredicate(format: "label LIKE 'Card checkout complete:*'")
        waitForElementToAppear(app.staticTexts.containing(checkoutCompletePredicate).element(boundBy: 0))

        // wait for validate & Capture button enabled
        sleep(10)

        // tap Capture
        app.buttons["Capture Order"].tap()

        // Check for success message
        let resultPredicate = NSPredicate(format: "label LIKE 'Capture Status:*'")
        sleep(15)
        waitForElementToAppear(app.staticTexts.containing(resultPredicate).element(boundBy: 0))
        XCTAssertTrue(app.staticTexts.containing(resultPredicate).element(boundBy: 0).exists);
    }
    
    func testAuthorizePayment() {
        app = XCUIApplication()
        app.launchArguments.append("-Authorize")
        app.launch()

        // wait for PP UAT
        let uatExistsPredicate = NSPredicate(format: "label LIKE 'Fetched UAT:*'")
        waitForElementToAppear(app.staticTexts.containing(uatExistsPredicate).element(boundBy: 0))

        // tap Create Order button
        app.buttons["Create Order"].tap()

        // wait for Order ID
        let orderExistsPredicate = NSPredicate(format: "label LIKE 'Order ID:*'")
        waitForElementToAppear(app.staticTexts.containing(orderExistsPredicate).element(boundBy: 0))

        // fill out card fields
        let cardNumberTextField = app.textFields["Card Number"]
        cardNumberTextField.tap()
        cardNumberTextField.typeText("4000000000000051")

        let expiryTextField = app.textFields["MM/YY"]
        expiryTextField.tap()
        expiryTextField.typeText("01/22")

        let cvvTextField = app.textFields["CVV"]
        cvvTextField.tap()
        cvvTextField.typeText("123")

        // tap Submit
        app.buttons["Submit"].tap()
        let checkoutCompletePredicate = NSPredicate(format: "label LIKE 'Card checkout complete:*'")
        waitForElementToAppear(app.staticTexts.containing(checkoutCompletePredicate).element(boundBy: 0))

        // wait for validate & Authorize button enabled
        sleep(10)

        // tap Authorize
        app.buttons["Authorize Order"].tap()

        // Check for success message
        let resultPredicate = NSPredicate(format: "label LIKE 'Authorize Status:*'")
        sleep(15)
        waitForElementToAppear(app.staticTexts.containing(resultPredicate).element(boundBy: 0))
        XCTAssertTrue(app.staticTexts.containing(resultPredicate).element(boundBy: 0).exists);
    }

    // TODO: - This test will fail, since the card doesn't trigger a 3DS challenge.
    // Waiting for PP team to give us new test cards.
    func testCardContingencySuccess() {
        app = XCUIApplication()
        app.launch()

        // wait for PP UAT
        let uatExistsPredicate = NSPredicate(format: "label LIKE 'Fetched UAT:*'")
        waitForElementToAppear(app.staticTexts.containing(uatExistsPredicate).element(boundBy: 0))

        // tap Create Order button
        app.buttons["Create Order"].tap()

        // wait for Order ID
        let orderExistsPredicate = NSPredicate(format: "label LIKE 'Order ID:*'")
        waitForElementToAppear(app.staticTexts.containing(orderExistsPredicate).element(boundBy: 0))

        // fill out card fields
        let cardNumberTextField = app.textFields["Card Number"]
        cardNumberTextField.tap()
        cardNumberTextField.typeText("4000000000000051")

        let expiryTextField = app.textFields["MM/YY"]
        expiryTextField.tap()
        expiryTextField.typeText("01/23")

        let cvvTextField = app.textFields["CVV"]
        cvvTextField.tap()
        cvvTextField.typeText("123")

        // tap Submit
        app.buttons["Submit"].tap()

        // enter password in 3DS challenge web view
        self.waitForElementToAppear(getPasswordFieldQuery().element, timeout: 60)
        let passwordTextField = getPasswordFieldQuery().element
        passwordTextField.forceTapElement()
        sleep(2)
        passwordTextField.typeText("1234")

        // tap 3DS Submit button
        getSubmitButton().tap()

        let checkoutCompletePredicate = NSPredicate(format: "label LIKE 'Card checkout complete:*'")
        waitForElementToAppear(app.staticTexts.containing(checkoutCompletePredicate).element(boundBy: 0))
    }

    // MARK: - Helpers

    func getPasswordFieldQuery() -> XCUIElementQuery {
        return app.webViews.element.otherElements.children(matching: .other).children(matching: .secureTextField)
    }

    func getSubmitButton() -> XCUIElement {
        return app.webViews.element.otherElements.children(matching: .other).children(matching: .other).buttons["Submit"]
    }
}
