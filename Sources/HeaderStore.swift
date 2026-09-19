import AppKit
import Foundation

enum RecentsStore {
    static let displayName = "Header Peek"

    static var directory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/\(displayName)", isDirectory: true)
    }

    static var fileURL: URL {
        directory.appendingPathComponent("recents.json")
    }

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    private static let decoder = JSONDecoder()

    static func load() -> (items: [String], error: String?) {
        let url = fileURL
        guard FileManager.default.fileExists(atPath: url.path) else {
            return ([], nil)
        }
        do {
            let data = try Data(contentsOf: url)
            let items = try decoder.decode([String].self, from: data)
            return (items, nil)
        } catch {
            return ([], error.localizedDescription)
        }
    }

    static func save(_ items: [String]) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let trimmed = Array(items.prefix(20))
        let data = try encoder.encode(trimmed)
        try data.write(to: fileURL, options: .atomic)
    }
}

@MainActor
final class HeaderStore: ObservableObject {
    @Published var urlText = ""
    @Published var hops: [Hop] = []
    @Published var recents: [String] = []
    @Published var errorMessage: String?
    @Published var persistenceError: String?
    @Published var isFetching = false
    @Published var menuTitle = "Header Peek"

    init() {
        let loaded = RecentsStore.load()
        recents = loaded.items
        persistenceError = loaded.error
    }

    func fetch() async {
        guard !isFetching else { return }
        isFetching = true
        errorMessage = nil
        let text = urlText
        let outcome = await HeaderFetch.fetch(urlText: text)
        hops = outcome.hops
        errorMessage = outcome.errorMessage
        if let status = outcome.lastStatus {
            menuTitle = String(status)
        } else {
            menuTitle = "Header Peek"
        }
        if !outcome.hops.isEmpty {
            rememberRecent(text.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        isFetching = false
    }

    func useRecent(_ url: String) {
        urlText = url
    }

    func copyCurl() {
        let trimmed = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        copyToPasteboard(HeaderFetch.curlCommand(for: trimmed))
    }

    func copyHeaders() {
        guard let hop = hops.last else { return }
        copyToPasteboard(HeaderFetch.headersClipboardText(from: hop))
    }

    private func rememberRecent(_ url: String) {
        guard !url.isEmpty else { return }
        recents.removeAll { $0 == url }
        recents.insert(url, at: 0)
        if recents.count > 20 {
            recents = Array(recents.prefix(20))
        }
        do {
            try RecentsStore.save(recents)
        } catch {
            persistenceError = error.localizedDescription
        }
    }

    private func copyToPasteboard(_ string: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(string, forType: .string)
    }
}
