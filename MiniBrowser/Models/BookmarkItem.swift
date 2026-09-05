import Foundation

enum BookmarkKind: String, Codable, CaseIterable, Identifiable {
    case url
    case bookmarklet

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .url: return "URL"
        case .bookmarklet: return "Bookmarklet"
        }
    }
}

struct BookmarkItem: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var content: String
    var kind: BookmarkKind
    var autoRunDomain: String?

    init(id: UUID = UUID(),
         name: String,
         content: String,
         kind: BookmarkKind,
         autoRunDomain: String? = nil) {
        self.id = id
        self.name = name
        self.content = content
        self.kind = kind
        self.autoRunDomain = autoRunDomain
    }
}
