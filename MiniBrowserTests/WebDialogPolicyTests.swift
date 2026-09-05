import XCTest
@testable import MiniBrowser

final class WebDialogPolicyTests: XCTestCase {
    func testAutoDismissesOnlyExactTargetPageCookieRetryAlert() {
        XCTAssertTrue(WebDialogPolicy.shouldAutoDismissAlert(
            host: "img.2chan.net",
            message: "cookieを有効にしてもう一度送信してください"
        ))
        XCTAssertTrue(WebDialogPolicy.shouldAutoDismissAlert(
            host: "IMG.2CHAN.NET",
            message: "cookieを有効にして\nもう一度送信してください"
        ))
        XCTAssertFalse(WebDialogPolicy.shouldAutoDismissAlert(
            host: "img.2chan.net",
            message: "cookieが無いので投稿できません"
        ))
        XCTAssertFalse(WebDialogPolicy.shouldAutoDismissAlert(
            host: "example.com",
            message: "cookieを有効にしてもう一度送信してください"
        ))
    }
}
