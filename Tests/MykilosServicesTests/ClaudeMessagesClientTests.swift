import Testing
import Foundation
@testable import MykilosServices
@testable import MykilosKit

struct ClaudeMessagesClientTests {

    @Test func buildRequestSetztAnthropicHeaderUndBody() throws {
        let request = try ClaudeMessagesClient.buildRequest(
            url: URL(string: "https://api.anthropic.com/v1/messages")!,
            credentials: ClaudeCredentials(apiKey: "sk-ant-test", model: "claude-test"),
            projectID: "ME-24",
            signals: [.deadlineNear(projectID: "ME-24", days: 2)],
            insights: [
                AssistantInsight(
                    projectID: "ME-24",
                    summary: "Abnahme in 2 Tagen",
                    source: .calendar,
                    priority: .attention
                )
            ]
        )

        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "x-api-key") == "sk-ant-test")
        #expect(request.value(forHTTPHeaderField: "anthropic-version") == "2023-06-01")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")

        let body = try #require(request.httpBody)
        let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
        #expect(json?["model"] as? String == "claude-test")
        #expect(json?["max_tokens"] as? Int == 420)
    }

    @Test func buildRequestPayloadBeschreibtSignaleUndInsights() {
        let payload = ClaudeMessagesClient.buildRequestPayload(
            model: "claude-test",
            projectID: "ME-24",
            signals: [.reviewSuggested(projectID: "ME-24", label: "Angebot Tischlerei")],
            insights: [
                AssistantInsight(
                    projectID: "ME-24",
                    summary: "Neues Angebot erkannt",
                    detail: "Bitte prüfen",
                    source: .drive,
                    priority: .attention
                )
            ]
        )

        #expect(payload.messages.count == 1)
        #expect(payload.messages[0].content.contains("ME-24"))
        #expect(payload.messages[0].content.contains("Angebot Tischlerei"))
        #expect(payload.messages[0].content.contains("Neues Angebot erkannt"))
    }

    @Test func parseSummaryVerbindetTextBloecke() throws {
        let data = """
        {
          "content": [
            { "type": "text", "text": "Erster Satz." },
            { "type": "tool_use", "id": "ignored" },
            { "type": "text", "text": "Zweiter Satz." }
          ]
        }
        """.data(using: .utf8)!

        let summary = try ClaudeMessagesClient.parseSummary(from: data)
        #expect(summary == "Erster Satz.\n\nZweiter Satz.")
    }

    @Test func parseSummaryWirftBeiLeererAntwort() {
        let data = #"{"content":[{"type":"text","text":"   "}]}"#.data(using: .utf8)!
        #expect(throws: ClaudeClientError.emptyResponse) {
            try ClaudeMessagesClient.parseSummary(from: data)
        }
    }

    @Test func parseSummaryWirftBeiKaputtemJSON() {
        let data = #"{"content":"kaputt"}"#.data(using: .utf8)!
        #expect(throws: ClaudeClientError.decodingFailed) {
            try ClaudeMessagesClient.parseSummary(from: data)
        }
    }
}
