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
        XCTAssertNoThrow(try makeResponse(withPayload: "true", type: Bool.self))
        XCTAssertNoThrow(try makeResponse(withPayload: "12", type: Int.self))
        XCTAssertNoThrow(try makeResponse(withPayload: "{ \"value\": \"payload\"}", type: DecodableTestStruct.self))

    }
    
    func test_throwsErrorIfGenericTypePassedIsWrong() {
        XCTAssertThrowsError(try makeResponse(withPayload: "true", type: Int.self))
        XCTAssertThrowsError(try makeResponse(withPayload: "1.3", type: Int.self))
    }
    
    // MARK: - Helpers
    
    private struct DecodableTestStruct: Codable {
        let value: String
    }
    
    private func makeResponse<T>(withPayload payload: String, type: T.Type) throws -> ResponseMock<T> {
        let json = EventsProtocolClientTests.makeJSON(name: "event:name:response", payload: payload)
        return try JSONDecoder().decode(ResponseMock<T>.self, from: json)
    }
    
    private func makeRedirectResponse() -> ResponseMock<[String: String?]> {
        return EventsProtocolClientTests.makeResponse(name: "event:name:redirect")
    }
    
    private func makeResponseWithRandomSuffix(excluding excludingStrings: [String] = []) -> ResponseMock<[String: String?]> {
        var name: String
        
        repeat {
            name = UUID().uuidString
        } while excludingStrings.first(where: { name.hasSuffix($0) }) != nil
        
        return EventsProtocolClientTests.makeResponse(name: name)
    }
}


