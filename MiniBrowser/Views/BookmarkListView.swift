import SwiftUI

struct BookmarkListView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: BookmarkStore
    let currentURL: URL?
    let onOpen: (BookmarkItem) -> Void
    let onValidateBookmarklet: (String) -> Void

    @State private var editorRequest: BookmarkEditorRequest?
    @State private var showingAddOptions = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.items) { item in
                    Button {
                        onOpen(item)
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.name)
                                .foregroundStyle(.primary)
                            Text(item.kind == .url ? item.content : "Bookmarklet")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                            if let domain = item.autoRunDomain {
                                Text("自動: \(domain)")
                                    .font(.caption2)
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    .contextMenu {
                        Button("編集") { edit(item) }
                    }
                    .swipeActions(edge: .trailing) {
                        Button("削除", role: .destructive) {
                            store.delete(item)
                        }
                    }
                    .draggable(item.id.uuidString)
                    .dropDestination(for: String.self) { values, _ in
                        guard let rawID = values.first,
                              let draggedID = UUID(uuidString: rawID) else { return false }
                        store.move(draggedID: draggedID, relativeTo: item.id)
                        return true
                    }
                }
            }
            .overlay {
                if store.items.isEmpty {
                    ContentUnavailableView("ブックマークなし",
                                           systemImage: "bookmark",
                                           description: Text("＋から追加できます"))
                }
            }
            .navigationTitle("ブックマーク")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddOptions = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("追加")
                }
            }
            .confirmationDialog("追加方法", isPresented: $showingAddOptions) {
                Button("新規URL / Bookmarklet") {
                    editorRequest = BookmarkEditorRequest(existing: nil,
                                                           initialName: "",
                                                           initialContent: "",
                                                          initialKind: .url,
                                                          initialAutoRunDomain: nil)
                }
                Button("現在ページを追加") {
                    guard let currentURL else { return }
                    editorRequest = BookmarkEditorRequest(existing: nil,
                                                           initialName: currentURL.host ?? currentURL.absoluteString,
                                                           initialContent: currentURL.absoluteString,
                                                          initialKind: .url,
                                                          initialAutoRunDomain: nil)
                }
                .disabled(currentURL == nil)
                Button("キャンセル", role: .cancel) {}
            }
            .sheet(item: $editorRequest) { request in
                BookmarkEditorView(request: request) { item in
                    store.save(item)
                    if item.kind == .bookmarklet {
                        onValidateBookmarklet(item.content)
                    }
                }
            }
        }
    }

    private func edit(_ item: BookmarkItem) {
        editorRequest = BookmarkEditorRequest(existing: item,
                                               initialName: item.name,
                                               initialContent: item.content,
                                               initialKind: item.kind,
                                               initialAutoRunDomain: item.autoRunDomain)
    }
}
