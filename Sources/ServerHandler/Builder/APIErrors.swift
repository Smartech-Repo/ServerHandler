//
//  APIErrors.swift
//
//
//  Created by Ahsan Ateeq on 19/02/2024.
//

import Foundation

public enum APIErrors: Error {
    case notFound
    case urlError
    case networkUnavailable
    case mismatchType
    case decodingError
}

extension APIErrors: LocalizedError {
    public var errorDescription: String?{
        switch self {
        case .notFound:
            return "not found data"
        case .urlError:
            return "url is error"
        case .networkUnavailable:
            return "networkUnavailable"
        case .mismatchType:
            return "types not identical"
        case .decodingError:
            return "decoding Error"
        }
    }
}
