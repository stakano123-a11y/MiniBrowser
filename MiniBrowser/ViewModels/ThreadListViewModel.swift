import Combine
import Foundation

@MainActor
final class ThreadListViewModel: ObservableObject {
    private enum Keys {
        static let sort = "ThreadListSort"
        static let expanded = "ThreadListExpanded"
        static let openCounts = "ThreadListOpenCounts"
    }

    @Published private(set) var items: [ThreadListItem] = []
    @Published private(set) var selectedSort: ThreadListSort
    @Published private(set) var isExpanded: Bool
    @Published private(set) var isRefreshing = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var openCounts: [String: Int]

    private let service: ThreadListService
    private let defaults: UserDefaults
    private var isSceneActive = true
    private var hasStarted = false
    private var listLoadTask: Task<Void, Never>?
    private var thumbnailLoadTask: Task<Void, Never>?
    private var openerTextLoadTask: Task<Void, Never>?
    private var refreshLoopTask: Task<Void, Never>?

    init(service: ThreadListService = ThreadListService(),
         defaults: UserDefaults = .standard) {
        self.service = service
        self.defaults = defaults
        self.selectedSort = ThreadListSort(
            rawValue: defaults.string(forKey: Keys.sort) ?? ""
        ) ?? .momentum
        self.isExpanded = defaults.object(forKey: Keys.expanded) == nil
            ? true
            : defaults.bool(forKey: Keys.expanded)
        self.openCounts = defaults.dictionary(forKey: Keys.openCounts)?
            .compactMapValues { ($0 as? NSNumber)?.intValue } ?? [:]
    }

    deinit {
        listLoadTask?.cancel()
        thumbnailLoadTask?.cancel()
        openerTextLoadTask?.cancel()
        refreshLoopTask?.cancel()
    }

    func start() {
        guard !hasStarted else { return }
        hasStarted = true
        if isExpanded {
            refresh()
        }
        updateRefreshLoop()
    }

    func setSceneActive(_ active: Bool) {
        guard isSceneActive != active else { return }
        isSceneActive = active
        if !active {
            cancelContentLoads()
        } else if isExpanded {
            refresh()
        }
        updateRefreshLoop()
    }

    func toggleExpanded() {
        isExpanded.toggle()
        defaults.set(isExpanded, forKey: Keys.expanded)
        if isExpanded {
            refresh()
        } else {
            cancelContentLoads()
            isRefreshing = false
        }
        updateRefreshLoop()
    }

    func selectSort(_ sort: ThreadListSort) {
        guard selectedSort != sort else { return }
        selectedSort = sort
        defaults.set(sort.rawValue, forKey: Keys.sort)
        cancelContentLoads()
        refresh()
    }

    func refresh() {
        guard isExpanded, isSceneActive else { return }
        listLoadTask?.cancel()
        let sort = selectedSort
        isRefreshing = true
        errorMessage = nil

        listLoadTask = Task { [weak self] in
            guard let self else { return }
            do {
                let loaded = try await service.fetchList(sort: sort, limit: 60)
                try Task.checkCancellation()
                guard selectedSort == sort else { return }
                items = mergeLoadedItems(loaded, with: items)
                isRefreshing = false
                startThumbnailLoadingIfNeeded(sort: sort)
                startOpenerTextLoadingIfNeeded(sort: sort)
            } catch is CancellationError {
                isRefreshing = false
            } catch {
                isRefreshing = false
                errorMessage = "更新失敗"
            }
        }
    }

    func recordOpen(_ item: ThreadListItem) {
        openCounts[item.id, default: 0] += 1
        if openCounts.count > 1_000 {
            let excess = openCounts.count - 1_000
            let oldestIDs = openCounts.keys.sorted {
                (Int($0) ?? 0) < (Int($1) ?? 0)
            }.prefix(excess)
            for id in oldestIDs {
                openCounts.removeValue(forKey: id)
            }
        }
        defaults.set(openCounts, forKey: Keys.openCounts)
    }

    func openCount(for item: ThreadListItem) -> Int {
        openCounts[item.id, default: 0]
    }

    private func cancelContentLoads() {
        listLoadTask?.cancel()
        listLoadTask = nil
        thumbnailLoadTask?.cancel()
        thumbnailLoadTask = nil
        openerTextLoadTask?.cancel()
        openerTextLoadTask = nil
    }

    private func mergeLoadedItems(_ loaded: [ThreadListItem],
                                  with current: [ThreadListItem]) -> [ThreadListItem] {
        let existing = Dictionary(uniqueKeysWithValues: current.map { ($0.id, $0) })
        return loaded.map { item in
            guard let previous = existing[item.id],
                  previous.thumbnailURL == item.thumbnailURL else {
                return item
            }
            var merged = item
            merged.thumbnailData = previous.thumbnailData
            merged.thumbnailLoadFailed = previous.thumbnailData == nil ? false : previous.thumbnailLoadFailed
            merged.openerText = previous.openerText
            return merged
        }
    }

    private func startThumbnailLoadingIfNeeded(sort: ThreadListSort) {
        guard thumbnailLoadTask == nil else { return }
        thumbnailLoadTask = Task { [weak self] in
            guard let self else { return }
            await self.loadMissingThumbnails(sort: sort)
            guard !Task.isCancelled else { return }
            self.thumbnailLoadTask = nil
        }
    }

    private func loadMissingThumbnails(sort: ThreadListSort) async {
        while !Task.isCancelled, selectedSort == sort, isExpanded, isSceneActive {
            guard let item = items.first(where: {
                $0.thumbnailData == nil && !$0.thumbnailLoadFailed
            }) else { return }
            do {
                let data = try await service.thumbnailData(for: item,
                                                           referer: sort.url)
                guard !Task.isCancelled, selectedSort == sort else { return }
                if let index = items.firstIndex(where: { $0.id == item.id }) {
                    items[index].thumbnailData = data
                    items[index].thumbnailLoadFailed = false
                }
            } catch is CancellationError {
                return
            } catch {
                if let index = items.firstIndex(where: { $0.id == item.id }) {
                    items[index].thumbnailLoadFailed = true
                }
            }
            await Task.yield()
        }
    }

    private func startOpenerTextLoadingIfNeeded(sort: ThreadListSort) {
        guard openerTextLoadTask == nil else { return }
        openerTextLoadTask = Task { [weak self] in
            guard let self else { return }
            await self.loadMissingOpenerTexts(sort: sort)
            guard !Task.isCancelled else { return }
            self.openerTextLoadTask = nil
        }
    }

    private func loadMissingOpenerTexts(sort: ThreadListSort) async {
        while !Task.isCancelled, selectedSort == sort, isExpanded, isSceneActive {
            guard let item = items.first(where: { $0.openerText == nil }) else { return }
            let text: String
            do {
                text = try await service.openerText(for: item)
            } catch is CancellationError {
                return
            } catch {
                text = "本文取得失敗"
            }

            guard !Task.isCancelled, selectedSort == sort else { return }
            if let index = items.firstIndex(where: { $0.id == item.id }) {
                items[index].openerText = text
            }
            await Task.yield()
        }
    }

    private func updateRefreshLoop() {
        refreshLoopTask?.cancel()
        refreshLoopTask = nil
        guard hasStarted, isExpanded, isSceneActive else { return }

        refreshLoopTask = Task { [weak self] in
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .seconds(60))
                } catch {
                    return
                }
                guard let self, self.isExpanded, self.isSceneActive else { return }
                self.refresh()
            }
        }
    }
}
