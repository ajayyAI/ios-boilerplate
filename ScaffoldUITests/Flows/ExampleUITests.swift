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

    /// Xcode's built-in accessibility audit, run against the loaded Home screen. The
    /// set is narrowed: `.dynamicType` and `.contrast` report false positives on system
    /// controls, and a check that cries wolf is one that gets deleted. Every other
    /// category is a real defect a VoiceOver user would hit.
    func testHomePassesAccessibilityAudit() throws {
        let homeView = app.otherElements["HomeView"]
        homeView.buttons["refreshButton"].tap()
        XCTAssertTrue(homeView.staticTexts["userEmailLabel"].waitForExistence(timeout: 5))

        try app.performAccessibilityAudit(for: [
            .elementDetection, .hitRegion, .sufficientElementDescription, .textClipped, .trait,
        ]) { issue in
            // The audit's readability heuristic rejects any label without spaces, which
            // catches an email address. VoiceOver reads one fine ("example at example
            // dot com"), so that one shape is waived. Waive a specific issue, never a
            // whole audit type; the type is what catches the next regression.
            issue.auditType == .sufficientElementDescription && issue.element?.label.contains("@") == true
        }
    }
}
