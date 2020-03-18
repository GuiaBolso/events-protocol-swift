import Foundation

public protocol URLSessionAdapter {
    func dataTask(with url: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask
}
