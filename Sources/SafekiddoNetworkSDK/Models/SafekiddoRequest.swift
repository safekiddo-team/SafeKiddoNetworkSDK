import Foundation

public struct SafekiddoRequest: Codable {
    public let requestId: UUID?
    public let resource: String?
    public let url: String?
    public let resourceType: ResourceType?
    public let subject: String?
    public let subjectType: SubjectType?
    public let apiKey: String
    public let engines: [String]
    public let resultOperator: ResultOperator?
    public let logRequest: Bool?
    public let correlationId: String?
    
    public init(
        requestId: UUID? = nil,
        resource: String? = nil,
        url: String? = nil,
        resourceType: ResourceType? = nil,
        subject: String? = nil,
        subjectType: SubjectType? = nil,
        apiKey: String,
        engines: [String],
        resultOperator: ResultOperator? = nil,
        logRequest: Bool? = nil,
        correlationId: String? = nil
    ) {
        self.requestId      = requestId
        self.resource       = resource
        self.url            = url
        self.resourceType   = resourceType
        self.subject        = subject
        self.subjectType    = subjectType
        self.apiKey         = apiKey
        self.engines        = engines
        self.resultOperator = resultOperator
        self.logRequest     = logRequest
        self.correlationId  = correlationId
    }
    
    enum CodingKeys: String, CodingKey {
        case requestId      = "request_id"
        case resource
        case url
        case resourceType   = "resource_type"
        case subject
        case subjectType    = "subject_type"
        case apiKey         = "api_key"
        case engines
        case resultOperator = "result_operator"
        case logRequest     = "log_request"
        case correlationId
    }
}
