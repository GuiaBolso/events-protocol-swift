import Foundation

public protocol Response: Event { }

extension Response {
    public var isSuccess: Bool {
        return name.hasSuffix(":response")
    }
    
    public var isRedirect: Bool {
        return name.hasSuffix(":redirect")
    }
    
    public var isError: Bool {
        return !isRedirect && !isSuccess
    }
}
