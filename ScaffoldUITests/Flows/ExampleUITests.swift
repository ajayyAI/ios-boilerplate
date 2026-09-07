import XCTest

@MainActor
final class ExampleUITests: XCTestCase {
    private let app = XCUIApplication()

    /// The async variant of setUp is main-actor isolated; the synchronous one is
    /// nonisolated, so XCUIApplication calls cannot be made from it under Swift 6.
    override func setUp() async throws {
        continueAfterFailure = false
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
