import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: HeaderStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: FunTheme.sectionSpacing) {
            ExtraSearchField(title: "URL", prompt: "https://", text: $store.urlText)

            Button("Fetch") {
                Task { await store.fetch() }
            }
            .buttonStyle(.borderedProminent)
            .disabled(store.isFetching)

            if let persistenceError = store.persistenceError {
                Label(persistenceError, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let errorMessage = store.errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if store.hops.isEmpty {
                ExtraEmptyState(
                    title: "No headers yet",
                    detail: "Enter an http or https URL and Fetch.",
                    actionTitle: "Fetch"
                ) {
                    Task { await store.fetch() }
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: FunTheme.innerSpacing) {
                        ForEach(store.hops) { hop in
                            HopCard(hop: hop)
                        }
                    }
                }

                HStack(spacing: FunTheme.innerSpacing) {
                    Button("Copy as curl") {
                        store.copyCurl()
                    }
                    .buttonStyle(.bordered)
                    Button("Copy headers") {
                        store.copyHeaders()
                    }
                    .buttonStyle(.bordered)
                }
            }

            if !store.recents.isEmpty {
                Text("Recents")
                    .font(.headline)
                ForEach(store.recents, id: \.self) { recent in
                    Button {
                        store.useRecent(recent)
                    } label: {
                        Text(recent)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    .extraRowSurface()
                }
            }

            ExtraSettingsFooter()
        }
        .animation(reduceMotion ? nil : FunTheme.spring, value: store.hops.count)
        .animation(reduceMotion ? nil : FunTheme.spring, value: store.errorMessage)
        .animation(reduceMotion ? nil : FunTheme.spring, value: store.recents)
        .funPanel()
    }
}

private struct HopCard: View {
    let hop: Hop

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(hop.method) \(hop.status) \(hop.statusText)")
                .font(.headline)
            Text(hop.url)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
            Text("\(hop.durationMs) ms")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(Array(hop.interestingHeaders.enumerated()), id: \.offset) { _, header in
                headerRow(header)
            }

            if !hop.otherHeaders.isEmpty {
                Text("Other")
                    .font(.subheadline)
                    .padding(.top, 4)
                ForEach(Array(hop.otherHeaders.enumerated()), id: \.offset) { _, header in
                    headerRow(header)
                }
            }
        }
        .extraRowSurface()
    }

    private func headerRow(_ header: (name: String, value: String)) -> some View {
        Text("\(header.name): \(header.value)")
            .font(.system(.caption, design: .monospaced))
            .textSelection(.enabled)
            .fixedSize(horizontal: false, vertical: true)
    }
}
