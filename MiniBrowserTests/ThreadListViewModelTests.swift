import Foundation
import XCTest
@testable import MiniBrowser

@MainActor
final class ThreadListViewModelTests: XCTestCase {
    func testOpenCountUpdatesAndPersistsAcrossViewModels() {
        let suiteName = "ThreadListViewModelTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let item = ThreadListItem(
            id: "1234567890",
            threadURL: URL(string: "https://img.2chan.net/b/res/1234567890.htm")!,
            thumbnailURL: URL(string: "https://img.2chan.net/b/cat/123s.jpg")!,
            replyCount: 10,
            thumbnailData: nil,
            openerText: "本文"
        )

        let firstModel = ThreadListViewModel(defaults: defaults)
        XCTAssertEqual(firstModel.openCount(for: item), 0)
        firstModel.recordOpen(item)
        firstModel.recordOpen(item)
        XCTAssertEqual(firstModel.openCount(for: item), 2)

        let restoredModel = ThreadListViewModel(defaults: defaults)
        XCTAssertEqual(restoredModel.openCount(for: item), 2)
    }
}
