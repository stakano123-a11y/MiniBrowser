import Combine
import Foundation

@MainActor
final class BookmarkStore: ObservableObject {
    private enum Keys {
        static let items = "bookmarkItems"
    }

    @Published private(set) var items: [BookmarkItem]
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Keys.items),
           let decoded = try? JSONDecoder().decode([BookmarkItem].self, from: data) {
            items = decoded
        } else {
            items = []
        }
    }

    func save(_ item: BookmarkItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
        } else {
            items.append(item)
        }
        persist()
    }

    func delete(_ item: BookmarkItem) {
        items.removeAll { $0.id == item.id }
        persist()
    }

    func move(draggedID: UUID, relativeTo targetID: UUID) {
        guard draggedID != targetID,
              let source = items.firstIndex(where: { $0.id == draggedID }),
              let initialTarget = items.firstIndex(where: { $0.id == targetID }) else { return }
        let item = items.remove(at: source)
        let adjustedTarget = items.firstIndex(where: { $0.id == targetID }) ?? items.endIndex
        let insertion = source < initialTarget ? adjustedTarget + 1 : adjustedTarget
        items.insert(item, at: min(max(0, insertion), items.endIndex))
        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        defaults.set(data, forKey: Keys.items)
    }
}
