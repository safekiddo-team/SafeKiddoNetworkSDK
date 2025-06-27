import Foundation

// MARK: – RESPONSE

public struct SafekiddoResponse: Codable {
    public let requestId: UUID?
    public let resource: String?
    public let resourceType: ResourceType?
    public let subject: String?
    public let subjectType: SubjectType?
    public let apiKey: String?
    public let engines: [String]?
    public let resultOperator: ResultOperator?
    public let logRequest: Bool?

    public let partner: String?
    public let result: PolicyResult?

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
        case partner
        case result
    }
}

// MARK: – ENGINE RESULT

public struct EngineResult: Codable {
    public let engine: String
    public let categoryId: Int
    public let categoryName: String
    public let subcategoryId: Int
    public let subcategoryName: String
    public let resultCode: Int

    enum CodingKeys: String, CodingKey {
        case engine
        case categoryId       = "category_id"
        case categoryName     = "category_name"
        case subcategoryId    = "subcategory_id"
        case subcategoryName  = "subcategory_name"
        case resultCode       = "result_code"
    }
}

// MARK: – DECISION

public struct Decision: Codable {
    public let action: ResultAction
    public let engines: [EngineResult]
}

// MARK: – POLICY RESULT

public struct PolicyResult: Codable {
    public let url: Decision?
    public let application: Decision?
}
