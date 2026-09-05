import SwiftUI

struct ThreadListView: View {
    @ObservedObject var model: ThreadListViewModel
    let onOpenThread: (URL) -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            listGrid
        }
        .background(Color(uiColor: .systemBackground))
    }

    private var header: some View {
        HStack(spacing: 4) {
            ForEach(ThreadListSort.allCases) { sort in
                Button(sort.title) {
                    model.selectSort(sort)
                }
                .font(.caption2.weight(model.selectedSort == sort ? .bold : .regular))
                .foregroundStyle(model.selectedSort == sort ? .white : .primary)
                .padding(.horizontal, 6)
                .frame(height: 26)
                .background(model.selectedSort == sort ? Color.blue : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 5))
            }

            Spacer(minLength: 2)

            if let error = model.errorMessage {
                Text(error)
                    .font(.caption2)
                    .foregroundStyle(.red)
                    .lineLimit(1)
            }

            Button(action: model.refresh) {
                if model.isRefreshing {
                    ProgressView()
                        .controlSize(.mini)
                } else {
                    Image(systemName: "arrow.clockwise")
                }
            }
            .frame(width: 28, height: 28)
            .accessibilityLabel("カタログを更新")

            Button(action: model.toggleExpanded) {
                Image(systemName: "chevron.down")
                    .frame(width: 28, height: 28)
            }
            .accessibilityLabel("スレ一覧を閉じる")
        }
        .padding(.horizontal, 5)
        .frame(height: 32)
        .background(.bar)
    }

    private var listGrid: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 4),
                GridItem(.flexible(), spacing: 4)
            ], spacing: 4) {
                ForEach(model.items) { item in
                    Button {
                        onOpenThread(item.threadURL)
                    } label: {
                        HStack(spacing: 5) {
                            AsyncImage(url: item.thumbnailURL) { image in
                                image.resizable().scaledToFit()
                            } placeholder: {
                                Color.secondary.opacity(0.12)
                            }
                            .frame(width: 32, height: 32)
                            .clipped()

                            Text(item.openerText ?? "本文取得中…")
                                .font(.caption2)
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 4)
                        .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
                        .background(Color(uiColor: .secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(item.openerText ?? "本文取得中")
                }
            }
            .padding(4)
        }
    }
}

struct ThreadListCollapsedBar: View {
    @ObservedObject var model: ThreadListViewModel

    var body: some View {
        Button(action: model.toggleExpanded) {
            HStack(spacing: 6) {
                Image(systemName: "chevron.up")
                Text("スレ一覧")
                    .font(.caption.weight(.semibold))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(height: 28)
        .background(.bar)
        .accessibilityLabel("スレ一覧を開く")
    }
}
