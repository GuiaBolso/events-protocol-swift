import XCTest
@testable import EventsProtocolClient

class ResponseTests: XCTestCase {
    func test_successResponse() {
        let response = makeSuccessfulResponse()
        
        XCTAssertTrue(response.isSuccess)
        XCTAssertFalse(response.isRedirect)
        XCTAssertFalse(response.isError)
    }
    
    func test_redirectResponse() {
        let response = makeRedirectResponse()
        
        XCTAssertFalse(response.isSuccess)
        XCTAssertTrue(response.isRedirect)
        XCTAssertFalse(response.isError)
    }
    
    func test_errorResponse() {
        (0...1000).forEach { _ in
            let response = makeResponseWithRandomSuffix(excluding: [":redirect", ":response"])
            XCTAssertFalse(response.isSuccess)
            XCTAssertFalse(response.isRedirect)
            XCTAssertTrue(response.isError)
        }
    }
    
    func test_decodesPayloadToGenericPassedType() {
        let trueResponse = makeResponse(withPayload: "true".data(using: .utf8)!)
        XCTAssertTrue(try trueResponse.get(\.payload, as: Bool.self))
        
        let intResponse = makeResponse(withPayload: "12".data(using: .utf8)!)
        XCTAssertEqual(try intResponse.get(\.payload, as: Int.self), 12)
        
        let decodeTest = try! JSONEncoder().encode(DecodableTestStruct(value: "payload"))
        let testResponse = makeResponse(withPayload: decodeTest)
        
        XCTAssertNoThrow(try testResponse.get(\.payload, as: DecodableTestStruct.self))
    }
    
    func test_throwsErrorIfGenericTypePassedIsWrong() {
        let sut = makeResponse(withPayload: "true".data(using: .utf8)!)
        XCTAssertThrowsError(try sut.get(\.payload, as: Int.self))
    }
    
    func test_throwsErrorIfKeypathPassedIsWrong() {
        let sut = makeResponse(withPayload: "123".data(using: .utf8)!)
        XCTAssertThrowsError(try sut.get(\.identity, as: Int.self))
    }
    
    // MARK: - Helpers
    
    private struct DecodableTestStruct: Codable {
        let value: String
    }
    
    private func makeResponse(withPayload payload: Data) -> Response {
        return Response(
            name: "event:name:error",
            version: Int.random(in: 1...10),
            id: UUID().uuidString,
            flowId: UUID().uuidString,
            payload: payload,
            identity: UUID().uuidString.data(using: .utf8)!,
            auth: UUID().uuidString.data(using: .utf8)!,
            metadata: UUID().uuidString.data(using: .utf8)!
        )
    }
    
    private func makeRedirectResponse() -> Response {
        return Response(
            name: "event:name:redirect",
            version: Int.random(in: 1...10),
            id: UUID().uuidString,
            flowId: UUID().uuidString,
            payload: UUID().uuidString.data(using: .utf8)!,
            identity: UUID().uuidString.data(using: .utf8)!,
            auth: UUID().uuidString.data(using: .utf8)!,
            metadata: UUID().uuidString.data(using: .utf8)!
        )
    }
    
    private func makeResponseWithRandomSuffix(excluding excludingStrings: [String] = []) -> Response {
        var name: String
        
        repeat {
            name = UUID().uuidString
        } while excludingStrings.first(where: { name.hasSuffix($0) }) != nil
        
        return Response(
            name: name,
            version: Int.random(in: 1...10),
            id: UUID().uuidString,
            flowId: UUID().uuidString,
            payload: UUID().uuidString.data(using: .utf8)!,
            identity: UUID().uuidString.data(using: .utf8)!,
            auth: UUID().uuidString.data(using: .utf8)!,
            metadata: UUID().uuidString.data(using: .utf8)!
        )
    }
    
    private func makeSuccessfulResponse() -> Response {
        return Response(
            name: "event:response",
            version: Int.random(in: 1...10),
            id: UUID().uuidString,
            flowId: UUID().uuidString,
            payload: UUID().uuidString.data(using: .utf8)!,
            identity: UUID().uuidString.data(using: .utf8)!,
            auth: UUID().uuidString.data(using: .utf8)!,
            metadata: UUID().uuidString.data(using: .utf8)!
        )
    }
}
