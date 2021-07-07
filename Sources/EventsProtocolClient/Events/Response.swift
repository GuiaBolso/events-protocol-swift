import Foundation

public struct Response: Event {
    public let name: String
    public let version: Int
    public let id: String
    public let flowId: String
    public let payload: Data
    public let identity: Data
    public let auth: Data
    public let metadata: Data
    
    public var isSuccess: Bool {
        return name.hasSuffix(":response")
    }
    
    public var isRedirect: Bool {
        return name.hasSuffix(":redirect")
    }
    
    public var isError: Bool {
        return !isRedirect && !isSuccess
    }
    
    public func get<T: Decodable>(_ propertyKeyPath: KeyPath<Self, Data>, as type: T.Type) throws -> T {
        let property = self[keyPath: propertyKeyPath]
        return try JSONDecoder().decode(T.self, from: property)
    }
}

extension Response: Decodable { }
