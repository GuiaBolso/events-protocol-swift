import XCTest
import EventsProtocolClient

class HTTPClientTests: XCTestCase {
    
    func testClient_send_requestsDataOnRightBaseURL() {
        let urlRequest = URLRequest(url: URL(string: "https://any-url.com")!)
        let (sut, sessionMock, _) = createSUT()
        
        send(urlRequest: urlRequest, with: sut, completion: { _ in
            let expectedURL = URL(string: "https://any-url.com")
            XCTAssertEqual([expectedURL], sessionMock.urlsRequested)
        })
    }
    
    func testClient_send_callsResume() {
        let (sut, sessionMock, _) = createSUT()
        
        send(with: sut, completion: { _ in
            XCTAssertEqual(sessionMock.dataTask?.resumeCalls, 1)
        })
    }

    func testClient_send_succeedsWithValidURLSessionResponse() {
        let expectedData = "Some data".data(using: .utf8)
        assertSendWillSucceed(
            stubbedData: expectedData,
            stubbedResponse: anyHTTPURLResponse(),
            with: "Some data"
        )
    }
    
    func testClient_send_respondsWithErrorWhenURLSessionRespondsWithError() {
        assertSendWillFail(
            stubbedError: NSError(domain: "", code: -999, userInfo: [:])
        )
    }
    
    func testClient_send_respondsWithErrorToInvalidURLSessionResponses() {
        assertSendWillFail(
            stubbedData: nil, stubbedResponse: nil, stubbedError: nil
        )
        
        assertSendWillFail(
            stubbedData: nil, stubbedResponse: anyHTTPURLResponse(), stubbedError: nil
        )
        
        assertSendWillFail(
            stubbedData: anyData(), stubbedResponse: nil, stubbedError: nil
        )
        
        assertSendWillFail(
            stubbedData: anyData(), stubbedResponse: nil, stubbedError: anyError()
        )
        
        assertSendWillFail(
            stubbedData: nil, stubbedResponse: anyHTTPURLResponse(), stubbedError: anyError()
        )
        
        assertSendWillFail(
            stubbedData: anyData(), stubbedResponse: anyHTTPURLResponse(), stubbedError: anyError()
        )
        
        assertSendWillFail(
            stubbedData: anyData(), stubbedResponse: anyURLResponse(), stubbedError: nil
        )
    }
    
    // MARK: - HELPERS
    
    private func assertSendWillSucceed(stubbedData: Data? = nil, stubbedResponse: URLResponse? = nil, stubbedError: Error? = nil, with expectedResponse: String, file: StaticString = #file, line: UInt = #line) {
        let (sut,_ , taskMock) = createSUT()

        taskMock.dataToReturn = stubbedData
        taskMock.responseToReturn = stubbedResponse
        taskMock.errorToReturn = stubbedError
        
        send(with: sut, completion: { returnedResult in
            switch returnedResult {
            case .success(let returnedValue):
                XCTAssertEqual(String(data: returnedValue, encoding: .utf8), expectedResponse)
            default:
                XCTFail("Expected success with \(expectedResponse), returned \(returnedResult) instead")
            }
        })
    }
    
    private func assertSendWillFail(stubbedData: Data? = nil, stubbedResponse: URLResponse? = nil, stubbedError: Error? = nil, file: StaticString = #file, line: UInt = #line) {
        let (sut,_ , taskMock) = createSUT()

        taskMock.dataToReturn = stubbedData
        taskMock.responseToReturn = stubbedResponse
        taskMock.errorToReturn = stubbedError
        
        send(with: sut, completion: { returnedResult in
            switch returnedResult {
            case .failure(let error):
                XCTAssertNotNil(error)
            default:
                XCTFail("Expected an error, returned \(returnedResult) instead")
            }
        })
    }
    
    private func send(urlRequest: URLRequest? = nil, with sut: HTTPClient, completion: @escaping (Result<Data, Error>) -> Void, file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "waiting for client response")

        sut.send(urlRequest: urlRequest ?? anyURLRequest()) { data in
            completion(data)
            exp.fulfill()
        }

        wait(for: [exp], timeout: 5)
    }
    
    private func anyData() -> Data {
        return UUID().uuidString.data(using: .utf8)!
    }
    
    private func anyError() -> Error {
        return NSError(domain: "any error", code: -999, userInfo: nil)
    }
    
    private func anyHTTPURLResponse() -> HTTPURLResponse {
        return HTTPURLResponse(
            url: URL(string: "https://www.a-url.com")!,
            statusCode: Int.random(in: 100...600),
            httpVersion: nil,
            headerFields: nil
        )!
    }
    
    private func anyURLResponse() -> URLResponse {
        return URLResponse(
            url: URL(string: "https://www.a-url.com")!,
            mimeType: nil,
            expectedContentLength: 0,
            textEncodingName: nil
        )
    }
    
    private func anyURLRequest() -> URLRequest {
        return URLRequest(url: URL(string: "https://www.a-url.com")!)
    }
    
    private func createSUT() -> (HTTPClient, URLSessionMock, DataTaskMock) {
        let session = URLSessionMock()
        let dataTask = DataTaskMock()
        session.dataTask = dataTask
        let sut = HTTPClient(urlSession: session)
        return (sut, session, dataTask)
    }

    private class DataTaskMock: URLSessionDataTask {
        var completionHandler: ((Data?, URLResponse?, Error?) -> Void)?
        var resumeCalls: Int
        
        var dataToReturn: Data?
        var errorToReturn: Error?
        var responseToReturn: URLResponse?
        
        override init() {
            self.resumeCalls = 0
        }
        
        override func resume() {
            resumeCalls += 1
            completionHandler?(
                dataToReturn,
                responseToReturn,
                errorToReturn
            )
        }
    }

    private class URLSessionMock: URLSessionAdapter {
        var dataTask: DataTaskMock?
        var requests = [URLRequest]()
        var urlsRequested: [URL] {
            return requests.compactMap { $0.url }
        }
        
        func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
            requests.append(request)
            
            dataTask?.completionHandler = completionHandler
            
            return dataTask!
        }
    }
}

