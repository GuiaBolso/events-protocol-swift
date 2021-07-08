import Foundation

public class EventClient {
    public enum Error: Swift.Error {
        case invalidResponse(Data)
        case eventError(Data)
        case eventRedirect(Data)
        case invalidPayload(Any?)
    }
    
    private let httpClient: HTTPClientAdapter
    
    public init(
        httpClient: HTTPClientAdapter = HTTPClient()
    ) {
        self.httpClient = httpClient
    }
    
    public func sendEvent<T, U>(
        url: URL,
        event: T,
        headers: [String: String] = [:],
        timeout: TimeInterval = 60000,
        responseType: U.Type,
        completion: @escaping (Result<U, Swift.Error>) -> Void
    ) where T: Event, U: Decodable {
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
                    completion(.success(try self.parseResponse(data)))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func parseResponse<T>(_ data: Data) throws -> T where T: Decodable {
        guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary,
              let name = json["name"] as? String else {
            throw Error.invalidResponse(data)
        }
        
        if isRedirect(name) { throw Error.eventRedirect(data) }
        if isError(name) { throw Error.eventError(data) }
        
        let payload = json["payload"]
        if let payload = payload as? T {
            return payload
        } else if let dict = payload as? Data {
            return try JSONDecoder().decode(T.self, from: dict)
        } else {
            throw Error.invalidPayload(payload)
        }
    }
    
    private func isSuccess(_ name: String) -> Bool {
        return name.hasSuffix(":response")
    }
    
    private func isRedirect(_ name: String) -> Bool {
        return name.hasSuffix(":redirect")
    }
    
    private func isError(_ name: String) -> Bool {
        return !isRedirect(name) && !isSuccess(name)
    }
    
}
