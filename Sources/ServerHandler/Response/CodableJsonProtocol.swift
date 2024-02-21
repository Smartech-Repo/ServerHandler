//
//  CodableJsonProtocol.swift
//
//
//  Created by Ahsan Ateeq on 19/02/2024.
//

import Foundation

public protocol CodableJsonProtocol: Codable {
    var id: Int { get }
}

extension CodableJsonProtocol {
    public var id: Int {
        return 0
    }
}


public struct CodableMetaData: Codable {
    let current_page: Int
    let from: Int?
    let last_page: Int
    let per_page: Int?
    let to: Int?
    let total: Int
}

public struct CodableLinks: Codable {
    let first, last, prev, next: String?
}

