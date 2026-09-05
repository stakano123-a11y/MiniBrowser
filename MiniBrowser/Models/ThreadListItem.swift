import Foundation

enum ThreadListSort: String, CaseIterable, Identifiable, Sendable {
    case momentum
    case list
    case mostReplies

    var id: String { rawValue }

    var title: String {
        switch self {
        case .momentum: "勢い順"
        case .list: "カタログ順"
        case .mostReplies: "多順"
        }
    }

    var url: URL {
        switch self {
        case .momentum:
            URL(string: "https://img.2chan.net/b/futaba.php?mode=cat&sort=6")!
        case .list:
            URL(string: "https://img.2chan.net/b/futaba.php?mode=cat")!
        case .mostReplies:
            URL(string: "https://img.2chan.net/b/futaba.php?mode=cat&sort=3")!
        }
    }
}

struct ThreadListItem: Identifiable, Equatable, Sendable {
    let id: String
    let threadURL: URL
    let thumbnailURL: URL
    let replyCount: Int
    var openerText: String?
}
