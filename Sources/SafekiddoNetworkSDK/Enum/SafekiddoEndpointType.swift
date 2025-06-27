import Foundation

public enum SafekiddoEndpointType {
    case policy
    case url
    
    var pathComponent: String {
        switch self {
        case .policy:
            return "/check/policy"
        case .url:
            return "/check/url"
        }
    }
}
