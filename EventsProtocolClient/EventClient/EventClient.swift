import Foundation

public class EventClient {
    private let httpClient: HTTPClientAdapter
    
    public init(
        httpClient: HTTPClientAdapter = HTTPClient()
    ) {
        self.httpClient = httpClient
    }
    
    public func sendEvent<T>(url: URL, event: T, timeout: TimeInterval = 60000, completion: @escaping (Result<Response, Error>) -> Void) where T: Event {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.timeoutInterval = timeout
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try? JSONEncoder().encode(event)
        httpClient.send(urlRequest: urlRequest) { result in
            switch result {
            case .success(let data):
                do {
                    completion(.success(try JSONDecoder().decode(Response.self, from: data)))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
