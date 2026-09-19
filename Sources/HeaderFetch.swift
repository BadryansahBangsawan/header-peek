import Foundation

struct Hop: Identifiable {
    let id = UUID()
    var url: String
    var method: String
    var status: Int
    var statusText: String
    var durationMs: Int
    var headers: [(name: String, value: String)]

    var interestingHeaders: [(name: String, value: String)] {
        HeaderFetch.interestingNames.flatMap { key in
            headers.filter { $0.name.lowercased() == key }
        }
    }

    var otherHeaders: [(name: String, value: String)] {
        headers.filter { header in
            !HeaderFetch.interestingSet.contains(header.name.lowercased())
        }
    }
}

enum HeaderFetch {
    struct Outcome {
        var hops: [Hop]
        var errorMessage: String?
        var lastStatus: Int?
    }

    static let interestingNames: [String] = [
        "access-control-allow-origin",
        "access-control-allow-methods",
        "access-control-allow-headers",
        "access-control-allow-credentials",
        "access-control-expose-headers",
        "cache-control",
        "expires",
        "etag",
        "age",
        "content-type",
        "content-length",
        "content-encoding",
        "content-security-policy",
        "content-security-policy-report-only",
        "strict-transport-security",
        "server",
        "x-powered-by",
        "location",
        "vary",
        "www-authenticate",
    ]

    static let interestingSet = Set(interestingNames)

    private static let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpShouldSetCookies = false
        configuration.httpCookieAcceptPolicy = .never
        configuration.timeoutIntervalForRequest = 15
        return URLSession(configuration: configuration)
    }()

    static func fetch(urlText: String) async -> Outcome {
        let trimmed = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let startURL = URL(string: trimmed) else {
            return Outcome(hops: [], errorMessage: "Invalid URL", lastStatus: nil)
        }
        guard let scheme = startURL.scheme, !scheme.isEmpty else {
            return Outcome(hops: [], errorMessage: "Invalid URL", lastStatus: nil)
        }
        let lowered = scheme.lowercased()
        guard lowered == "http" || lowered == "https" else {
            return Outcome(hops: [], errorMessage: "URL must be http or https.", lastStatus: nil)
        }

        var hops: [Hop] = []
        var current = startURL
        var lastStatus: Int?

        for hopIndex in 0..<10 {
            switch await oneHop(url: current) {
            case .failure(let message):
                return Outcome(hops: hops, errorMessage: message, lastStatus: lastStatus)
            case .success(let hop):
                hops.append(hop)
                lastStatus = hop.status
                let isRedirect = (300..<400).contains(hop.status)
                if !isRedirect {
                    return Outcome(hops: hops, errorMessage: nil, lastStatus: lastStatus)
                }
                if hopIndex == 9 {
                    return Outcome(
                        hops: hops,
                        errorMessage: "Stopped after 10 redirects.",
                        lastStatus: lastStatus
                    )
                }
                guard let location = locationValue(in: hop.headers),
                      let next = URL(string: location, relativeTo: current)
                else {
                    return Outcome(hops: hops, errorMessage: nil, lastStatus: lastStatus)
                }
                current = next.absoluteURL
            }
        }

        return Outcome(hops: hops, errorMessage: nil, lastStatus: lastStatus)
    }

    static func curlCommand(for url: String) -> String {
        let escaped = url.replacingOccurrences(of: "'", with: "'\\''")
        return "curl -sS -D - -o /dev/null --max-redirs 10 -L '\(escaped)'"
    }

    static func headersClipboardText(from hop: Hop) -> String {
        hop.headers.map { "\($0.name): \($0.value)\n" }.joined()
    }

    private static func oneHop(url: URL) async -> HopResult {
        let start = CFAbsoluteTimeGetCurrent()
        switch await perform("HEAD", url: url) {
        case .http(let response):
            if response.statusCode == 405 || response.statusCode == 501 {
                return await finishGET(url: url, start: start)
            }
            return .success(makeHop(url: url, method: "HEAD", response: response, start: start))
        case .urlError:
            return await finishGET(url: url, start: start)
        case .failed(let message):
            return .failure(message)
        }
    }

    private static func finishGET(url: URL, start: CFAbsoluteTime) async -> HopResult {
        switch await perform("GET", url: url) {
        case .http(let response):
            return .success(makeHop(url: url, method: "GET", response: response, start: start))
        case .urlError(let error):
            return .failure(error.localizedDescription)
        case .failed(let message):
            return .failure(message)
        }
    }

    private enum HopResult {
        case success(Hop)
        case failure(String)
    }

    private enum PerformResult {
        case http(HTTPURLResponse)
        case urlError(URLError)
        case failed(String)
    }

    private static func perform(_ method: String, url: URL) async -> PerformResult {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(
            "HeaderPeek/1.0 (engineer.badry.headerpeek)",
            forHTTPHeaderField: "User-Agent"
        )
        do {
            let (_, response) = try await session.data(for: request, delegate: RedirectBlocker())
            guard let http = response as? HTTPURLResponse else {
                return .failed("Invalid response.")
            }
            return .http(http)
        } catch let error as URLError {
            return .urlError(error)
        } catch {
            return .failed(error.localizedDescription)
        }
    }

    private static func makeHop(
        url: URL,
        method: String,
        response: HTTPURLResponse,
        start: CFAbsoluteTime
    ) -> Hop {
        let durationMs = Int((CFAbsoluteTimeGetCurrent() - start) * 1000)
        return Hop(
            url: url.absoluteString,
            method: method,
            status: response.statusCode,
            statusText: HTTPURLResponse.localizedString(forStatusCode: response.statusCode),
            durationMs: durationMs,
            headers: sortedHeaders(response.allHeaderFields)
        )
    }

    private static func sortedHeaders(_ fields: [AnyHashable: Any]) -> [(name: String, value: String)] {
        var pairs: [(name: String, value: String)] = []
        pairs.reserveCapacity(fields.count)
        for (key, value) in fields {
            let name: String
            if let stringKey = key as? String {
                name = stringKey
            } else {
                name = String(describing: key)
            }
            let valueString: String
            if let stringValue = value as? String {
                valueString = stringValue
            } else {
                valueString = String(describing: value)
            }
            pairs.append((name: name, value: valueString))
        }
        pairs.sort { lhs, rhs in
            lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
        return pairs
    }

    private static func locationValue(in headers: [(name: String, value: String)]) -> String? {
        headers.first { $0.name.lowercased() == "location" }?.value
    }

    final class RedirectBlocker: NSObject, URLSessionTaskDelegate {
        func urlSession(
            _ session: URLSession,
            task: URLSessionTask,
            willPerformHTTPRedirection response: HTTPURLResponse,
            newRequest request: URLRequest,
            completionHandler: @escaping (URLRequest?) -> Void
        ) {
            completionHandler(nil)
        }
    }
}
