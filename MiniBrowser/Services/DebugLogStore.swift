import Foundation

@MainActor
final class DebugLogStore {
    private enum Keys {
        static let entries = "debugLogEntries"
    }

    private(set) var entries: [DebugLogEntry]
    private let defaults: UserDefaults
    private let capacity: Int

    init(defaults: UserDefaults = .standard, capacity: Int = 500) {
        self.defaults = defaults
        self.capacity = capacity
        if let data = defaults.data(forKey: Keys.entries),
           let decoded = try? JSONDecoder().decode([DebugLogEntry].self, from: data) {
            entries = Array(decoded.suffix(capacity))
        } else {
            entries = []
        }
    }

    func append(action: String, fields: [(String, String)]) {
        entries.append(DebugLogEntry(action: action, fields: fields))
        if entries.count > capacity {
            entries.removeFirst(entries.count - capacity)
        }
        persist()
    }

    func plainText(limit: Int = 50) -> String {
        entries.suffix(limit).map(\.plainText).joined(separator: "\n\n")
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        defaults.set(data, forKey: Keys.entries)
    }
}

