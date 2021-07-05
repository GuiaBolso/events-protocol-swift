import Foundation

public protocol HTTPClientAdapter {
    func send(urlRequest: URLRequest, completion: @escaping (Result<Data, Error>) -> Void)
}
