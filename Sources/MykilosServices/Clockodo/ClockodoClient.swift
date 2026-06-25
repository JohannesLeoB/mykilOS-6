import Foundation

// MARK: - ClockodoTimeEntry
public struct ClockodoTimeEntry: Identifiable, Equatable, Sendable {
    public var id: String
    public var label: String
    public var durationSeconds: Int

    public init(id: String, label: String, durationSeconds: Int) {
        self.id = id
        self.label = label
        self.durationSeconds = durationSeconds
    }
}

// MARK: - ClockodoError
public enum ClockodoError: Error, Sendable, Equatable {
    case notConnected
    case invalidResponse
    case httpError(Int)
    case decodingFailed
}

// MARK: - ClockodoFetching
public protocol ClockodoFetching: Sendable {
    func todaysEntries() async throws -> [ClockodoTimeEntry]
}

// MARK: - ClockodoClient
// Liest die heutigen Zeiteinträge des verbundenen Accounts. ZEITEN-Regel:
// reiner Lese-/Mapping-Layer, niemals zweite Zeit-Wahrheit, keine Buchung.
public struct ClockodoClient: ClockodoFetching {
    private let credentialsStore: ClockodoCredentialsStoring
    private let session: URLSession
    private let baseURL = "https://my.clockodo.com/api/v2/entries"

    public init(
        credentialsStore: ClockodoCredentialsStoring = KeychainClockodoCredentialsStore(),
        session: URLSession = .shared
    ) {
        self.credentialsStore = credentialsStore
        self.session = session
    }

    public func todaysEntries() async throws -> [ClockodoTimeEntry] {
        guard let credentials = try? credentialsStore.load() else {
            throw ClockodoError.notConnected
        }
        guard let url = Self.buildEntriesURL(baseURL: baseURL, now: Date()) else {
            throw ClockodoError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.setValue(credentials.email, forHTTPHeaderField: "X-ClockodoApiUser")
        request.setValue(credentials.apiKey, forHTTPHeaderField: "X-ClockodoApiKey")
        request.setValue("mykilOS6;\(credentials.email)", forHTTPHeaderField: "X-Clockodo-External-Application")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ClockodoError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw ClockodoError.httpError(http.statusCode) }

        return try Self.parseEntries(from: data)
    }

    // MARK: - Reine, testbare Bausteine (kein Netzwerk/Keychain)

    static func buildEntriesURL(baseURL: String, now: Date) -> URL? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let startOfDay = calendar.startOfDay(for: now)

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]

        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "time_since", value: isoFormatter.string(from: startOfDay)),
            URLQueryItem(name: "time_until", value: isoFormatter.string(from: now)),
        ]
        return components?.url
    }

    static func parseEntries(from data: Data) throws -> [ClockodoTimeEntry] {
        do {
            let decoded = try JSONDecoder().decode(ClockodoEntriesResponse.self, from: data)
            return decoded.entries.map { entry in
                ClockodoTimeEntry(
                    id: String(entry.id),
                    label: entry.projectsName ?? entry.customersName ?? "(ohne Projekt)",
                    durationSeconds: entry.duration ?? 0
                )
            }
        } catch {
            throw ClockodoError.decodingFailed
        }
    }
}

private struct ClockodoEntriesResponse: Decodable {
    var entries: [ClockodoEntryEntity]
}

private struct ClockodoEntryEntity: Decodable {
    var id: Int
    var customersName: String?
    var projectsName: String?
    var duration: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case customersName = "customers_name"
        case projectsName = "projects_name"
        case duration
    }
}
