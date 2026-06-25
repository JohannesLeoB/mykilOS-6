import Foundation

// MARK: - ClockodoCredentials
public struct ClockodoCredentials: Equatable, Sendable {
    public var email: String
    public var apiKey: String

    public init(email: String, apiKey: String) {
        self.email = email
        self.apiKey = apiKey
    }
}

// MARK: - ClockodoCredentialsStoring
public protocol ClockodoCredentialsStoring: Sendable {
    func store(_ credentials: ClockodoCredentials) throws
    func load() throws -> ClockodoCredentials?
    func clear() throws
}

// MARK: - KeychainClockodoCredentialsStore
// Clockodo authentifiziert über simple API-Key + E-Mail-Header, kein OAuth —
// nutzt den bestehenden generischen KeychainStore direkt (siehe
// Google/KeychainStore.swift), kein neuer Keychain-Code nötig.
public struct KeychainClockodoCredentialsStore: ClockodoCredentialsStoring {
    private let keychain: KeychainStore
    private static let service = "com.mykilos6.clockodo"
    private static let emailAccount = "email"
    private static let apiKeyAccount = "apiKey"

    public init(keychain: KeychainStore = KeychainStore()) {
        self.keychain = keychain
    }

    public func store(_ credentials: ClockodoCredentials) throws {
        try keychain.store(credentials.email, service: Self.service, account: Self.emailAccount)
        try keychain.store(credentials.apiKey, service: Self.service, account: Self.apiKeyAccount)
    }

    public func load() throws -> ClockodoCredentials? {
        guard let email = try keychain.load(service: Self.service, account: Self.emailAccount),
              let apiKey = try keychain.load(service: Self.service, account: Self.apiKeyAccount) else {
            return nil
        }
        return ClockodoCredentials(email: email, apiKey: apiKey)
    }

    public func clear() throws {
        try keychain.delete(service: Self.service, account: Self.emailAccount)
        try keychain.delete(service: Self.service, account: Self.apiKeyAccount)
    }
}
