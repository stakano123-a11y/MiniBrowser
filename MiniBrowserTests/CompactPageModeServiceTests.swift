import XCTest
@testable import MiniBrowser

final class CompactPageModeServiceTests: XCTestCase {
    func testScriptIsRestrictedToImgThreadPages() {
        let script = CompactPageModeService.scriptSource
        XCTAssertTrue(script.contains("location.hostname !== \"img.2chan.net\""))
        XCTAssertTrue(script.contains(#"\/res\/"#))
    }

    func testScriptIncludesRequestedFocusModeBehavior() {
        let script = CompactPageModeService.scriptSource
        XCTAssertTrue(script.contains("width=device-width, initial-scale=1"))
        XCTAssertTrue(script.contains(".minibrowser-targetpage-form .ftb2"))
        XCTAssertTrue(script.contains("minibrowser-targetpage-starter"))
        XCTAssertTrue(script.contains("minibrowser-own-response"))
        XCTAssertTrue(script.contains("MiniBrowser.TargetPageOwnPosts:"))
        XCTAssertTrue(script.contains("10 * 60 * 1000"),
                      "Unmatched post bodies must expire instead of remaining indefinitely.")
    }
}
