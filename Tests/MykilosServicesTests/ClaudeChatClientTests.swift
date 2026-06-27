import Testing
import Foundation
@testable import MykilosServices
@testable import MykilosKit

struct ClaudeChatClientTests {

    private let creds = ClaudeCredentials(apiKey: "sk-ant-test", model: "claude-sonnet-4-6")

    // MARK: Request: Header + System + alle Turns in Reihenfolge
    @Test func buildChatRequestEnthaeltSystemUndAlleTurns() throws {
        let messages: [ChatMessage] = [
            .text("Hallo", role: .user),
            .text("Hi, wie kann ich helfen?", role: .assistant),
            .text("Was ist Montag zu tun?", role: .user),
        ]
        let request = try ClaudeChatClient.buildChatRequest(
            url: URL(string: "https://api.anthropic.com/v1/messages")!,
            credentials: creds, messages: messages, system: "Du bist der Assistent.", maxTokens: 512
        )

        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "x-api-key") == "sk-ant-test")
        #expect(request.value(forHTTPHeaderField: "anthropic-version") == "2023-06-01")

        let json = try JSONSerialization.jsonObject(with: #require(request.httpBody)) as? [String: Any]
        #expect(json?["model"] as? String == "claude-sonnet-4-6")
        #expect(json?["max_tokens"] as? Int == 512)
        #expect(json?["system"] as? String == "Du bist der Assistent.")
        let wire = json?["messages"] as? [[String: Any]]
        #expect(wire?.count == 3)
        #expect(wire?[0]["role"] as? String == "user")
        #expect(wire?[1]["role"] as? String == "assistant")
        let firstContent = wire?[0]["content"] as? [[String: Any]]
        #expect(firstContent?[0]["type"] as? String == "text")
        #expect(firstContent?[0]["text"] as? String == "Hallo")
    }

    // MARK: Response-Parsing
    @Test func parseChatResponseLiestUndVerbindetText() throws {
        let data = #"{"content":[{"type":"text","text":"Antwort A."},{"type":"text","text":"Antwort B."}]}"#.data(using: .utf8)!
        #expect(try ClaudeChatClient.parseChatResponse(from: data) == "Antwort A.\n\nAntwort B.")
    }

    @Test func parseChatResponseWirftBeiLeer() {
        let data = #"{"content":[{"type":"text","text":"  "}]}"#.data(using: .utf8)!
        #expect(throws: ClaudeClientError.emptyResponse) { try ClaudeChatClient.parseChatResponse(from: data) }
    }

    // MARK: HTTP-Fehler-Mapping
    @Test func httpFehlerWerdenGemappt() throws {
        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        let r429 = HTTPURLResponse(url: url, statusCode: 429, httpVersion: nil, headerFields: ["retry-after": "30"])!
        let r529 = HTTPURLResponse(url: url, statusCode: 529, httpVersion: nil, headerFields: nil)!
        let r500 = HTTPURLResponse(url: url, statusCode: 500, httpVersion: nil, headerFields: nil)!
        #expect(ClaudeChatClient.mapHTTPError(status: 429, response: r429) == .rateLimited(retryAfter: 30))
        #expect(ClaudeChatClient.mapHTTPError(status: 529, response: r529) == .overloaded)
        #expect(ClaudeChatClient.mapHTTPError(status: 500, response: r500) == .httpError(500))
    }

    // MARK: chat() ohne Keychain → notConnected
    @Test func chatOhneVerbindungWirftNotConnected() async {
        let client = ClaudeChatClient(
            credentialsStore: FakeChatCredentials(stored: nil),
            httpClient: FakeChatHTTP(result: .success((Data(), HTTPURLResponse()))),
            baseURL: URL(string: "https://example.com")!
        )
        await #expect(throws: ClaudeClientError.notConnected) {
            _ = try await client.chat(messages: [.text("hi", role: .user)], system: "s")
        }
    }

    // MARK: chat() Erfolgspfad über Fake-HTTP
    @Test func chatGibtGeparsteAntwortZurueck() async throws {
        let url = URL(string: "https://example.com")!
        let body = #"{"content":[{"type":"text","text":"Live-Antwort."}]}"#.data(using: .utf8)!
        let ok = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let client = ClaudeChatClient(
            credentialsStore: FakeChatCredentials(stored: creds),
            httpClient: FakeChatHTTP(result: .success((body, ok))),
            baseURL: url
        )
        let answer = try await client.chat(messages: [.text("hi", role: .user)], system: "s")
        #expect(answer == "Live-Antwort.")
    }

    // MARK: chat() bei 429 → rateLimited
    @Test func chatMapptRateLimit() async {
        let url = URL(string: "https://example.com")!
        let r429 = HTTPURLResponse(url: url, statusCode: 429, httpVersion: nil, headerFields: ["retry-after": "12"])!
        let client = ClaudeChatClient(
            credentialsStore: FakeChatCredentials(stored: creds),
            httpClient: FakeChatHTTP(result: .success((Data(), r429))),
            baseURL: url
        )
        await #expect(throws: ClaudeClientError.rateLimited(retryAfter: 12)) {
            _ = try await client.chat(messages: [.text("hi", role: .user)], system: "s")
        }
    }
}

// MARK: - Fakes
private struct FakeChatCredentials: ClaudeCredentialsStoring {
    let stored: ClaudeCredentials?
    func store(_ credentials: ClaudeCredentials) throws {}
    func load() throws -> ClaudeCredentials? { stored }
    func clear() throws {}
}

private struct FakeChatHTTP: ClaudeHTTPClient {
    let result: Result<(Data, URLResponse), Error>
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try result.get()
    }
}
