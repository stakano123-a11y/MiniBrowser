import XCTest
@testable import MiniBrowser

@MainActor
final class BookmarkStoreTests: XCTestCase {
    func testLegacyBookmarkWithoutAutoRunDomainStillDecodes() throws {
        let id = UUID()
        let json = """
        {"id":"\(id.uuidString)","name":"Legacy","content":"javascript:true","kind":"bookmarklet"}
        """
        let item = try JSONDecoder().decode(BookmarkItem.self, from: Data(json.utf8))

        XCTAssertEqual(item.id, id)
        XCTAssertNil(item.autoRunDomain)
    }

    func testOrderPersistsAfterDragMove() throws {
        let suiteName = "BookmarkStoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let first = BookmarkItem(name: "First", content: "https://one.example", kind: .url)
        let second = BookmarkItem(name: "Second", content: "https://two.example", kind: .url)
        let store = BookmarkStore(defaults: defaults)
        store.save(first)
        store.save(second)
        store.move(draggedID: second.id, relativeTo: first.id)

        let restored = BookmarkStore(defaults: defaults)
        XCTAssertEqual(restored.items.map(\.id), [second.id, first.id])
    }
}
