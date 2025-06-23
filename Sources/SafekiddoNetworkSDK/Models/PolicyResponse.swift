import Foundation

struct PolicyResponse: Codable {
    let requestId: UUID?
    let resource: String?
    let resourceType: ResourceType?
    let subject: String?
    let subjectType: SubjectType?
    let apiKey: String?
    let engines: [String]?
    let resultOperator: ResultOperator?
    let logRequest: Bool?

   
    let partner: String?
    let result: PolicyResult?

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

struct EngineResult: Codable {
    let engine: String
    let categoryId: Int
    let categoryName: String
    let subcategoryId: Int
    let subcategoryName: String
    let resultCode: Int
    
    enum CodingKeys: String, CodingKey {
        case engine
        case categoryId       = "category_id"
        case categoryName     = "category_name"
        case subcategoryId    = "subcategory_id"
        case subcategoryName  = "subcategory_name"
        case resultCode       = "result_code"
    }
}


struct Decision: Codable {
    let action: ResultAction
    let engines: [EngineResult]
}


struct PolicyResult: Codable {
    let url: Decision?
    let application: Decision?
}
