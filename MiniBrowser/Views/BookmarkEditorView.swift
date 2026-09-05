import SwiftUI

struct BookmarkEditorRequest: Identifiable {
    let id = UUID()
    let existing: BookmarkItem?
    let initialName: String
    let initialContent: String
    let initialKind: BookmarkKind
    let initialAutoRunDomain: String?
}

struct BookmarkEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let request: BookmarkEditorRequest
    let onSave: (BookmarkItem) -> Void

    @State private var name: String
    @State private var content: String
    @State private var kind: BookmarkKind
    @State private var autoRunEnabled: Bool
    @State private var autoRunDomain: String

    init(request: BookmarkEditorRequest, onSave: @escaping (BookmarkItem) -> Void) {
        self.request = request
        self.onSave = onSave
        _name = State(initialValue: request.initialName)
        _content = State(initialValue: request.initialContent)
        _kind = State(initialValue: request.initialKind)
        _autoRunEnabled = State(initialValue: request.initialAutoRunDomain != nil)
        _autoRunDomain = State(initialValue: request.initialAutoRunDomain ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("名前") {
                    TextField("名前", text: $name)
                }

                Section("種類") {
                    Picker("種類", selection: $kind) {
                        ForEach(BookmarkKind.allCases) { kind in
                            Text(kind.displayName).tag(kind)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section(kind == .url ? "URL" : "JavaScript本文") {
                    if kind == .url {
                        TextField("https://example.com", text: $content, axis: .vertical)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)
                    } else {
                        TextEditor(text: $content)
                            .font(.system(.body, design: .monospaced))
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .frame(minHeight: 320)
                    }
                }

                if kind == .bookmarklet {
                    Section("自動実行") {
                        Toggle("指定ドメインで自動実行", isOn: $autoRunEnabled)
                        if autoRunEnabled {
                            TextField("img.2chan.net", text: $autoRunDomain)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .keyboardType(.URL)
                            Text("完全一致したドメインのページ読み込み後に実行します")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(request.existing == nil ? "追加" : "編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let finalName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        let item = BookmarkItem(id: request.existing?.id ?? UUID(),
                                                name: finalName.isEmpty ? "名称未設定" : finalName,
                                                content: content,
                                                kind: kind,
                                                autoRunDomain: kind == .bookmarklet && autoRunEnabled
                                                    ? BookmarkAutoRunMatcher.normalizedDomain(autoRunDomain)
                                                    : nil)
                        onSave(item)
                        dismiss()
                    }
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                              (kind == .bookmarklet && autoRunEnabled &&
                               BookmarkAutoRunMatcher.normalizedDomain(autoRunDomain) == nil))
                }
            }
        }
    }
}
