import Combine
import Foundation

@MainActor
final class ThreadListViewModel: ObservableObject {
    private enum Keys {
        static let sort = "ThreadListSort"
        static let expanded = "ThreadListExpanded"
    }

    @Published private(set) var items: [ThreadListItem] = []
    @Published private(set) var selectedSort: ThreadListSort
    @Published private(set) var isExpanded: Bool
    @Published private(set) var isRefreshing = false
    @Published private(set) var errorMessage: String?

    private let service: ThreadListService
    private let defaults: UserDefaults
    private var isSceneActive = true
    private var hasStarted = false
    private var loadTask: Task<Void, Never>?
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
    }

    deinit {
        loadTask?.cancel()
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
        updateRefreshLoop()
    }

    func toggleExpanded() {
        isExpanded.toggle()
        defaults.set(isExpanded, forKey: Keys.expanded)
        if isExpanded {
            refresh()
        } else {
            loadTask?.cancel()
            isRefreshing = false
        }
        updateRefreshLoop()
    }

    func selectSort(_ sort: ThreadListSort) {
        guard selectedSort != sort else { return }
        selectedSort = sort
        defaults.set(sort.rawValue, forKey: Keys.sort)
        refresh()
    }

    func refresh() {
        guard isExpanded, isSceneActive else { return }
        loadTask?.cancel()
        let sort = selectedSort
        isRefreshing = true
        errorMessage = nil

        loadTask = Task { [weak self] in
            guard let self else { return }
            do {
                let loaded = try await service.fetchList(sort: sort, limit: 30)
                try Task.checkCancellation()
                guard selectedSort == sort else { return }
                items = loaded
                isRefreshing = false
                await loadOpenerTexts(for: loaded, sort: sort)
            } catch is CancellationError {
                isRefreshing = false
            } catch {
                isRefreshing = false
                errorMessage = "更新失敗"
            }
        }
    }

    private func loadOpenerTexts(for loaded: [ThreadListItem],
                                 sort: ThreadListSort) async {
        for item in loaded {
            guard !Task.isCancelled, selectedSort == sort else { return }
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
