import Foundation
import Observation

// MARK: - ClaudeCredentials
public struct ClaudeCredentials: Equatable, Sendable {
    public var apiKey: String
    public var model: String

    public init(apiKey: String, model: String) {
        self.apiKey = apiKey
        self.model = model
    }
}

// MARK: - ClaudeConnectionStatus
public enum ClaudeConnectionStatus: Equatable, Sendable {
    case disconnected
    case connected
    case error(String)
}

// MARK: - ClaudeCredentialsStoring
public protocol ClaudeCredentialsStoring: Sendable {
    func store(_ credentials: ClaudeCredentials) throws
    func load() throws -> ClaudeCredentials?
    func clear() throws
}

// MARK: - KeychainClaudeCredentialsStore
public struct KeychainClaudeCredentialsStore: ClaudeCredentialsStoring {
    private let keychain: KeychainStore
    private static let service = "com.mykilos6.claude"
    private static let apiKeyAccount = "apiKey"
    private static let modelAccount = "model"

    public init(keychain: KeychainStore = KeychainStore()) {
        self.keychain = keychain
    }

    public func store(_ credentials: ClaudeCredentials) throws {
        try keychain.store(credentials.apiKey, service: Self.service, account: Self.apiKeyAccount)
        try keychain.store(credentials.model, service: Self.service, account: Self.modelAccount)
    }

    public func load() throws -> ClaudeCredentials? {
        guard let apiKey = try keychain.load(service: Self.service, account: Self.apiKeyAccount),
              let model = try keychain.load(service: Self.service, account: Self.modelAccount) else {
            return nil
        }
        return ClaudeCredentials(apiKey: apiKey, model: model)
    }

    public func clear() throws {
        try keychain.delete(service: Self.service, account: Self.apiKeyAccount)
        try keychain.delete(service: Self.service, account: Self.modelAccount)
    }
}

// MARK: - ClaudeAuthService
@MainActor
@Observable
public final class ClaudeAuthService {
    public static let defaultModel = "claude-sonnet-4-6"

    public private(set) var status: ClaudeConnectionStatus

    private let credentialsStore: ClaudeCredentialsStoring

    public init(credentialsStore: ClaudeCredentialsStoring = KeychainClaudeCredentialsStore()) {
        self.credentialsStore = credentialsStore
        self.status = (try? credentialsStore.load()) != nil ? .connected : .disconnected
    }

    public func storedCredentials() throws -> ClaudeCredentials? {
        try credentialsStore.load()
    }

    public func connect(apiKey: String, model: String) throws {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedModel = model.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedKey.isEmpty == false else {
            status = .error("API-Key fehlt")
            throw ClaudeClientError.notConnected
        }
        let modelValue = trimmedModel.isEmpty ? Self.defaultModel : trimmedModel
        do {
            try credentialsStore.store(ClaudeCredentials(apiKey: trimmedKey, model: modelValue))
            status = .connected
        } catch {
            status = .error(String(describing: error))
            throw error
        }
    }

    public func disconnect() throws {
        try credentialsStore.clear()
        status = .disconnected
    }
}
