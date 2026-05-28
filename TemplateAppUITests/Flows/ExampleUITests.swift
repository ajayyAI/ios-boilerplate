import XCTest

final class ExampleUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testHomeShowsEmailAfterRefresh() {
        let homeView = app.otherElements["HomeView"]
        let userEmailLabel = homeView.staticTexts["userEmailLabel"]
        let refreshButton = homeView.buttons["refreshButton"]

        XCTAssertFalse(userEmailLabel.exists)

        refreshButton.tap()

        XCTAssertTrue(userEmailLabel.waitForExistence(timeout: 5))
        XCTAssertEqual(userEmailLabel.label, "example@example.com")
    }
}
