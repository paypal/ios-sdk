import XCTest

extension XCTestCase {
    func waitForElementToAppear(_ element: XCUIElement, timeout: TimeInterval = 10,  file: String = #file, line: UInt = #line) {
        expectation(for: NSPredicate(format: "exists == true"), evaluatedWith: element, handler: nil)
        
        waitForExpectations(timeout: timeout) { (error) -> Void in
            if (error != nil) {
                let message = "Failed to find \(element) after \(timeout) seconds."
                self.recordFailure(withDescription: message, inFile: file, atLine: Int(line), expected: true)
            }
        }
    }
    
    func waitForElementToBeHittable(_ element: XCUIElement, timeout: TimeInterval = 10,  file: String = #file, line: UInt = #line) {
        expectation(for: NSPredicate(format: "exists == true"), evaluatedWith: element, handler: nil)
        
        waitForExpectations(timeout: timeout) { (error) -> Void in
            if (error != nil) {
                let message = "Failed to find \(element) after \(timeout) seconds."
                self.recordFailure(withDescription: message, inFile: file, atLine: Int(line), expected: true)
            }
        }
    }
}

extension XCUIElement {
    func forceTapElement() {
        isHittable ? tap() : coordinate(withNormalizedOffset: CGVector(dx: 0.0, dy: 0.0)).tap()
    }
}
