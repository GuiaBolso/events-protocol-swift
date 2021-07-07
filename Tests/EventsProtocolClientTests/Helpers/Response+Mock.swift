import Foundation
import EventsProtocolClient

struct ResponseMock<T: Codable>: Response {
    typealias Payload = T
    typealias Identity = [String: String?]
    typealias Auth = [String: String?]
    typealias Metadata = [String: String?]
    
    let name: String
    let version: Int
    let id: String
    let flowId: String
    let payload: Payload
    let identity: Identity
    let auth: Auth
    let metadata: Metadata
}

func makeSuccessfulResponse() -> ResponseMock<[String: String?]> {
    return makeResponse(name: "event:response")
}

func makeResponse(
    name: String = "event:response"
) -> ResponseMock<[String: String?]> {
    let json = makeJSON(name: name, payload: "{}")
    return try! JSONDecoder().decode(ResponseMock.self, from: json)
}

func makeJSON(
    name: String,
    payload: String
) -> Data {
    return """
{
  "name": "\(name)",
  "version": \(Int.random(in: 1...10)),
  "id": "\(UUID().uuidString)",
  "flowId": "\(UUID().uuidString)",
  "auth": {},
  "identity": {},
  "payload": \(payload),
  "metadata": {}
}
""".data(using: .utf8)!
}
