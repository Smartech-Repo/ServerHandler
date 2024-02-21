//
//  ServerHandlerConstants.swift
//
//
//  Created by Ahsan Ateeq on 19/02/2024.
//

import Foundation

public class ServerHandlerConstants {
    
    public static let shared = ServerHandlerConstants()
    
    var baseURL: URL? = nil
    var authorizationToken: String? = nil
    var customHeaders: [String: String]? = nil
    
    public func configure(baseURL: String? = nil,
                          authorizationBearerToken: String? = nil,
                          headers: [String: String]? = nil) {
        
        if let url = baseURL {
            self.baseURL = URL(string: url)
        }
        
        self.authorizationToken = authorizationBearerToken
        self.customHeaders = headers
    }
    
    public func setBearerAuthorizationToken(token: String) {
        self.authorizationToken = token
    }
    
    public func setHeaders(_ headers: [String: String]) {
        self.customHeaders = headers
    }
}
