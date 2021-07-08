import XCTest
@testable import EventsProtocolClient

class EventClientTests: XCTestCase {
    
    func testEventClient_sendEvent_makesOnePostRequest() {
        let (sut, httpClient) = makeSUT()
        
        sut.sendEvent(url: anyURL(), event: makeRequestEvent(), responseType: String?.self) { _ in }
        
        XCTAssertEqual(httpClient.requestsMethods, ["POST"])
    }
    
    func testEventClient_setsDefaultTimeoutToURLRequest() {
        let (sut, httpClient) = makeSUT()
        
        sut.sendEvent(url: anyURL(), event: makeRequestEvent(), responseType: String?.self) { _ in }
        XCTAssertEqual(httpClient.requestsTimeouts, [60000])
    }
    
    func testEventClient_setsCustomTimeoutToURLRequest() {
        let (sut, httpClient) = makeSUT()
        
        sut.sendEvent(url: anyURL(), event: makeRequestEvent(), timeout: 5000, responseType: String?.self) { _ in }
        XCTAssertEqual(httpClient.requestsTimeouts, [5000])
    }
    
    func testEventClient_sendEvent_addApplicationJsonContentTypeHeader() {
        let (sut, httpClient) = makeSUT()
        
        sut.sendEvent(url: anyURL(), event: makeRequestEvent(), responseType: String?.self) { _ in }
        
        XCTAssertEqual(httpClient.requestsHeaders, [["Content-Type": "application/json"]])
    }
    
    func testEventClient_sendEvent_makesOneRequestToTheRightURL() {
        let (sut, httpClient) = makeSUT()
        
        let expectedUrl = URL(string: "https://some-url.com")!
        
        sut.sendEvent(url: expectedUrl, event: makeRequestEvent(), responseType: String?.self) { _ in }
        
        XCTAssertEqual(httpClient.requestsURLs, [expectedUrl])
    }
    
    func testEventClient_sendEvent_mapsEventToRequestsBody() {
        let (sut, httpClient) = makeSUT()
        
        let expectedEvent = makeRequestEvent()
        sut.sendEvent(url: anyURL(), event: expectedEvent, responseType: String?.self) { _ in }

        let expectedBodies = [ try! JSONEncoder().encode(expectedEvent) ]
        XCTAssertEqual(httpClient.requestsBodies, expectedBodies)
    }
    
    func test_sendEvent_failureOnHTTPClientReturnsErrorOnEventClient() {
        let failingClient = HTTPClientFailureStub()
        let sut = EventClient(httpClient: failingClient)
        
        let exp = expectation(description: "wait for event client response")
        sut.sendEvent(url: anyURL(), event: makeRequestEvent(), responseType: String?.self) { result in
            switch result {
            case .failure(let error):
                XCTAssertNotNil(error)
            default:
                XCTFail("Expected failure, got \(result) instead")
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1)
    }
    
    func test_sendEvent_successHTTPClientRequestsWithInvalidResponseWillEncodeError() {
        let successClient = HTTPClientSuccessStub()
        let sut = EventClient(httpClient: successClient)
        
        successClient.response = "invalid response".data(using: .utf8)
        
        let exp = expectation(description: "wait for event client response")
        sut.sendEvent(url: anyURL(), event: makeRequestEvent(), responseType: String?.self) { result in
            switch result {
            case .failure(let error):
                XCTAssertNotNil(error)
            default:
                XCTFail("Expected EventClient.Error.invalidResponse, got \(result) instead")
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1)
    }
    
    func test_sendEvent_successHTTPClientRequestsWithValidResponseWillReturnAResponse() {
        let successClient = HTTPClientSuccessStub()
        let sut = EventClient(httpClient: successClient)
        
        let expectedResponse = 1
        successClient.response = makeJSONResponse(payload: "\(expectedResponse)")
        
        let exp = expectation(description: "wait for event client response")
        sut.sendEvent(url: anyURL(), event: makeRequestEvent(), responseType: Int.self) { result in
            switch result {
            case .success(let returnedResponse):
                XCTAssertNotNil(returnedResponse)
            default:
                XCTFail("Expected success with \(expectedResponse), got \(result) instead")
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1)
    }
    
    func test_sendEvent_successHTTPClientRequestsWithEventErrorWillReturnAEventError() {
        let successClient = HTTPClientSuccessStub()
        let sut = EventClient(httpClient: successClient)
        
        successClient.response = makeJSONResponse(name: "event:error")
        
        let exp = expectation(description: "wait for event client response")
        sut.sendEvent(url: anyURL(), event: makeRequestEvent(), responseType: Int.self) { result in
            switch result {
            case .failure(let returnedResponse):
                switch returnedResponse as! EventClient.Error {
                case .eventError(_): break
                default:
                    XCTFail("Expected eventError, got \(result) instead")
                }
            default:
                XCTFail("Expected eventError, got \(result) instead")
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1)
    }
    
    func test_sendEvent_addParmsHeadersToURLRequest() {
        let (sut, httpClient) = makeSUT()
        
        sut.sendEvent(
            url: anyURL(),
            event: makeRequestEvent(),
            headers: ["Test": "value"],
            responseType: String?.self
        ) { _ in }
        
        
        XCTAssertEqual(
            httpClient.requestsHeaders,
            [["Content-Type": "application/json",
              "Test": "value"]]
        )
    }
    
    private func makeRequestEvent() -> TestRequestEvent {
        return TestRequestEvent(
            name: UUID().uuidString,
            version: Int.random(in: 1...10),
            id: UUID().uuidString,
            flowId: UUID().uuidString,
            payload: UUID().uuidString.data(using: .utf8)!,
            identity: UUID().uuidString.data(using: .utf8)!,
            auth: UUID().uuidString.data(using: .utf8)!,
            metadata: UUID().uuidString.data(using: .utf8)!
        )
    }
    
    private func makeSUT() -> (EventClient, HTTPClientMock) {
        let httpClient = HTTPClientMock()
        let sut = EventClient(httpClient: httpClient)
        
        return (sut, httpClient)
    }
    
    private func anyURL() -> URL {
        return URL(string: "https://any-url.com")!
    }
    
    private class HTTPClientMock: HTTPClientAdapter {
        var requestsMade = [URLRequest]()
        
        var requestsBodies: [Data] { return requestsMade.compactMap { $0.httpBody } }
        var requestsURLs: [URL] { return requestsMade.compactMap { $0.url } }
        var requestsMethods: [String] { return requestsMade.compactMap { $0.httpMethod } }
        var requestsTimeouts: [TimeInterval] { return requestsMade.compactMap { $0.timeoutInterval } }
        var requestsHeaders: [[String: String]] {
            return requestsMade.compactMap { $0.allHTTPHeaderFields }
        }
        
        func send(urlRequest: URLRequest, completion: @escaping (Result<Data, Error>) -> Void) {
            requestsMade.append(urlRequest)
        }
    }
    
    private class HTTPClientSuccessStub: HTTPClientAdapter {
        var response: Data?
        
        func send(urlRequest: URLRequest, completion: @escaping (Result<Data, Error>) -> Void) {
            completion(.success(response!))
        }
    }
    
    private class HTTPClientFailureStub: HTTPClientAdapter {
        func send(urlRequest: URLRequest, completion: @escaping (Result<Data, Error>) -> Void) {
            completion(.failure(NSError(domain: "some error", code: -999, userInfo: nil)))
        }
    }
    
    private func makeJSONResponse(
        name: String = "event:response",
        payload: String = "{}") -> Data {
        return """
            {
              "name": "\(name)",
              "version": 1,
              "id": "test-id1212",
              "flowId": "test-flow12121",
              "auth": {},
              "identity": {},
              "payload": \(payload),
              "metadata": {}
            }
            """.data(using: .utf8)!
    }
    
    private struct TestRequestEvent: Event {
        let name: String
        let version: Int
        let id: String
        let flowId: String
        let payload: Data
        let identity: Data
        let auth: Data
        let metadata: Data
    }
}
