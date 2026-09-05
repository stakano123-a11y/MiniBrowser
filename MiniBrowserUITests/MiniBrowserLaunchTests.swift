import XCTest

final class MiniBrowserLaunchTests: XCTestCase {
    func testListLaunchRemainsRunning() {
        let app = XCUIApplication()
        app.launchArguments += ["-ThreadListExpanded", "YES",
                                "-ThreadListSort", "momentum"]
        app.launch()

        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 15))
        Thread.sleep(forTimeInterval: 20)
        XCTAssertEqual(app.state, .runningForeground,
                       "MiniBrowser terminated while the list and opener texts were loading.")
    }
}
