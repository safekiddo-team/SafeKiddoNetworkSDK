import Foundation

public enum SubjectType: String, Codable { case kid, device, ip }
public enum ResourceType: String, Codable { case url, application }
public enum ResultAction: String, Codable { case allow, deny, other }
public enum ResultOperator: String, Codable { case and, or }
