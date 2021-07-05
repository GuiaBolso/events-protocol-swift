import Foundation

public final class HTTPClient: HTTPClientAdapter {
    private let urlSession: URLSessionAdapter
    
    public struct UnexpectedResponseError: Error { }
    
    public init(
        urlSession: URLSessionAdapter = URLSession.shared
     ) {
        self.urlSession = urlSession
    }
    
    public func send(urlRequest: URLRequest, completion: @escaping (Result<Data, Error>) -> Void) {
        let task = urlSession.dataTask(with: urlRequest) { (data, response, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let data = data,
                (response as? HTTPURLResponse) != nil {
                completion(.success(data))
            } else {
                completion(.failure(UnexpectedResponseError()))
            }
        }
        task.resume()
    }
}

extension URLSession: URLSessionAdapter { }
