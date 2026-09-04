import XCTest
@testable import MiniBrowser

final class DebugLogEntryTests: XCTestCase {
    func testSensitiveAssignmentsAreRedacted() {
        let entry = DebugLogEntry(action: "Test", fields: [
            ("DETAIL", "token=abc123&mode=1 password=hunter2")
        ])
        XCTAssertFalse(entry.plainText.contains("abc123"))
        XCTAssertFalse(entry.plainText.contains("hunter2"))
        XCTAssertTrue(entry.plainText.contains("[REDACTED]"))
    }

    func testSensitiveURLQueryValuesAreRedacted() {
        let url = URL(string: "https://example.com/path?token=abc&normal=ok")!
        let safe = LogSanitizer.url(url)
        XCTAssertFalse(safe.contains("token=abc"))
        XCTAssertTrue(safe.contains("normal=ok"))
    }
}
