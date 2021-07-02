import XCTest


class ExampleUITests: XCTestCase {
    override func setUpWithError() throws {
        super.setUpWithError()
        
        continueAfterFailure = false
    }

    func testExample() throws {
        let app = XCUIApplication()
        app.launch()
        
        XCTAssertTrue(true)
    }
}
