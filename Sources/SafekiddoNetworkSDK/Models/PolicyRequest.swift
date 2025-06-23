import Foundation

struct PolicyRequest: Codable {
    let requestId: UUID?
    let resource: String
    let resourceType: ResourceType
    let subject: String
    let subjectType: SubjectType
    let apiKey: String?            
    let engines: [String]
    let resultOperator: ResultOperator?
    let logRequest: Bool?

    enum CodingKeys: String, CodingKey {
        case requestId      = "request_id"
        case resource
        case resourceType   = "resource_type"
        case subject
        case subjectType    = "subject_type"
        case apiKey         = "api_key"
        case engines
        case resultOperator = "result_operator"
        case logRequest     = "log_request"
    }
}
