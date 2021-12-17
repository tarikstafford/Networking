//
//  APIClient.swift
//  RebtelDialConcept
//
//  Created by Tarik Stafford on 17/12/18.
//  Copyright © 2018 Tarik Stafford. All rights reserved.
//

import Foundation

public protocol APIRequest {
    associatedtype ReturnType: Codable
    var headers: [String:String]? { get }
    var body: Data? { get }
    var contentType: String { get }
    var method: RequestMethod { get }
    var path: String? { get }
    var queryItems: [URLQueryItem]? { get }
    var apiKey: String? { get }
    
    func localizedErrorDescription(statusCode: ResponseStatus) -> String?
}

extension APIRequest {
    // Defaults
    var method: RequestMethod { return .get }
    var contentType: String { return "application/json" }
    var queryParams: [String: String]? { return nil }
    var body: [String: Any]? { return nil }
    var headers: [String: String]? { return nil }
}

struct APIFailedResponse: Codable {
    var message: String
}
