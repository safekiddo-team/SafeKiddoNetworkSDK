import Foundation

public struct User: Codable {
    public let token: String
    public let isSubuser: Bool
    public let ownerId: String
    public let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case token
        case isSubuser = "is_subuser"
        case ownerId = "owner_id"
        case refreshToken = "refresh_token"
    }

    public init(token: String, isSubuser: Bool, ownerId: String, refreshToken: String) {
        self.token = token
        self.isSubuser = isSubuser
        self.ownerId = ownerId
        self.refreshToken = refreshToken
    }
}
