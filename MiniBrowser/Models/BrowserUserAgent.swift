import Foundation

struct BrowserUserAgent: Identifiable, Equatable, Sendable {
    let id: Int
    let name: String
    let value: String

    static let all: [BrowserUserAgent] = [
        .init(id: 1,
              name: "Safari iPhone",
              value: "Mozilla/5.0 (iPhone; CPU iPhone OS 18_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Mobile/15E148 Safari/604.1"),
        .init(id: 2,
              name: "Chrome iPhone",
              value: "Mozilla/5.0 (iPhone; CPU iPhone OS 18_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/140.0.7339.122 Mobile/15E148 Safari/604.1"),
        .init(id: 3,
              name: "Firefox iPhone",
              value: "Mozilla/5.0 (iPhone; CPU iPhone OS 18_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) FxiOS/143.0 Mobile/15E148 Safari/605.1.15"),
        .init(id: 4,
              name: "Edge iPhone",
              value: "Mozilla/5.0 (iPhone; CPU iPhone OS 18_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) EdgiOS/140.0 Mobile/15E148 Safari/605.1.15"),
        .init(id: 5,
              name: "Brave iPhone",
              value: "Mozilla/5.0 (iPhone; CPU iPhone OS 18_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.5 Mobile/15E148 Safari/604.1 Brave"),
        .init(id: 6,
              name: "DuckDuckGo iPhone",
              value: "Mozilla/5.0 (iPhone; CPU iPhone OS 18_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Mobile/15E148 DuckDuckGo/7 Safari/605.1.15"),
        .init(id: 7,
              name: "Opera iPhone",
              value: "Mozilla/5.0 (iPhone; CPU iPhone OS 18_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) OPiOS/6.1.0.11209 Mobile/15E148 Safari/9537.53"),
        .init(id: 8,
              name: "Safari iPad",
              value: "Mozilla/5.0 (iPad; CPU OS 18_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Mobile/15E148 Safari/604.1"),
        .init(id: 9,
              name: "Chrome iPad",
              value: "Mozilla/5.0 (iPad; CPU OS 18_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/140.0.7339.122 Mobile/15E148 Safari/604.1"),
        .init(id: 10,
              name: "Firefox iPad",
              value: "Mozilla/5.0 (iPad; CPU OS 18_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) FxiOS/143.0 Mobile/15E148 Safari/605.1.15")
    ]
}
