import Foundation

public protocol Event: Encodable {
    associatedtype Payload
    associatedtype Identity
    associatedtype Auth
    associatedtype Metadata
    
    var name: String { get }
    var version: Int { get }
    var id: String { get }
    var flowId: String { get }
    var payload: Payload { get }
    var identity: Identity { get }
    var auth: Auth { get }
    var metadata: Metadata { get }
}
