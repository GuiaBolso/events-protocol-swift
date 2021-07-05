import Foundation

public class EventClient {
    private let httpClient: HTTPClientAdapter
    
    public init(
        httpClient: HTTPClientAdapter = HTTPClient()
    ) {
        self.httpClient = httpClient
    }
    
    public func sendEvent<T>(
        url: URL,
        event: T,
        headers: [String: String] = [:],
        timeout: TimeInterval = 60000,
        completion: @escaping (Result<Response, Error>) -> Void
    ) where T: Event {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.timeoutInterval = timeout
        urlRequest.httpBody = try? JSONEncoder().encode(event)
        
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        headers.forEach { arg in
            let (value, key) = arg
            urlRequest.addValue(key, forHTTPHeaderField: value)
        }
        
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
