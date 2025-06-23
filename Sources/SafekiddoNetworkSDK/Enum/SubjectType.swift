import Foundation

enum SubjectType: String, Codable { case kid, device, ip }
enum ResourceType: String, Codable { case url, application }
enum ResultAction: String, Codable { case allow, deny, other }
enum ResultOperator: String, Codable { case and, or } 
