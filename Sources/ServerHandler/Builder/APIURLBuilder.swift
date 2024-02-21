//
//  APIURLBuilder.swift
//
//
//  Created by Ahsan Ateeq on 19/02/2024.
//

import Foundation

public enum HTTPMethods: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

public protocol APIURLBuilderProtocol {
    associatedtype TJSON: CodableJsonProtocol
    
    var baseURL: URL? {get}
    var pathComponents:[String] {get}
    var queryStrings:[URLQueryItem] {get}
    var JSONType: Codable.Type {get}
    var httpMethod: HTTPMethods {get}
    var authorizationToken: String? {get}
    var headers: [String: String]? {get}
    func buildURL() -> URL?
    func buildURLRequest() -> URLRequest?
    
    func fetch() async throws -> (jsonObj: TJSON?, requestURL: URL?)
    func fetch(_ completion: @escaping ((APIHandler<TJSON>.apiResultsCompletion) -> Void))
}

public protocol ApiBuilderWithPaging: APIURLBuilderProtocol {
    var page: Int? {get set}
    mutating func nextPageURL(currentMeta: CodableMetaData) -> URL?
    
}

extension APIURLBuilderProtocol {
    public var httpMethod:HTTPMethods {
        return .get
    }
    
    public var authorizationToken:String? {
        return ServerHandlerConstants.shared.authorizationToken
    }
    
    public var JSONType: Codable.Type {
        return TJSON.self
    }
    
    public var baseURL: URL? {
        return ServerHandlerConstants.shared.baseURL
    }
    
    public var headers: [String: String]? {
        return ServerHandlerConstants.shared.customHeaders
    }
    
    public func buildURL() -> URL? {
        var components = URLComponents()
        var base_url = self.baseURL
                
        components.queryItems = self.queryStrings
        self.pathComponents.forEach({base_url?.appendPathComponent($0)})

        guard base_url != nil else {
            return nil
        }
        
        components.path = base_url!.path
        components.host = base_url?.host
        components.scheme = base_url?.scheme
        components.port = base_url?.port
        components.fragment = base_url?.fragment

        return components.url(relativeTo: base_url)
    }
    
    public func buildURLRequest() -> URLRequest? {
        
        guard let url = self.buildURL() else {
            return nil
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = self.httpMethod.rawValue
        
        if let token = self.authorizationToken {
            urlRequest.setValue("bearer " + token, forHTTPHeaderField: "Authorization")
        }
        
        urlRequest.allowsCellularAccess = true
        if #available(iOS 13.0, *) {
            urlRequest.allowsConstrainedNetworkAccess = true
        }
        
        if #available(iOS 13.0, *) {
            urlRequest.allowsExpensiveNetworkAccess = true
        }
        
        if let headers = self.headers {
            for header in headers {
                urlRequest.addValue(header.value, forHTTPHeaderField: header.key)
            }
        }
        
        return urlRequest
    }
    
    public func fetch() async throws -> APIHandler<TJSON>.apiResults {
        try await APIHandler<TJSON>.fetchAPI(forURL: self)
    }
    
    public func fetch(_ completion: @escaping ((APIHandler<TJSON>.apiResultsCompletion) -> Void)) {
        APIHandler<TJSON>.fetchAPI(forURL: self, completion)
    }
}

extension ApiBuilderWithPaging {
    mutating func nextPageURL(currentMeta: CodableMetaData) -> URL? {
        let nextPageNumer = currentMeta.current_page + 1
        guard nextPageNumer <= currentMeta.last_page else {
            return nil
        }
        
        self.page = nextPageNumer
        return self.buildURL()
    }
}
