import Foundation

public struct PolicyRequest: Codable {
    public let requestId: UUID?
    public let resource: String
    public let resourceType: ResourceType
    public let subject: String
    public let subjectType: SubjectType
    public let apiKey: String?
    public let engines: [String]
    public let resultOperator: ResultOperator?
    public let logRequest: Bool?

    public init(
        requestId: UUID? = nil,
        resource: String,
        resourceType: ResourceType,
        subject: String,
        subjectType: SubjectType,
        apiKey: String? = nil,
        engines: [String],
        resultOperator: ResultOperator? = nil,
        logRequest: Bool? = nil
    ) {
        self.requestId      = requestId
        self.resource       = resource
        self.resourceType   = resourceType
        self.subject        = subject
        self.subjectType    = subjectType
        self.apiKey         = apiKey
        self.engines        = engines
        self.resultOperator = resultOperator
        self.logRequest     = logRequest
    }
}
