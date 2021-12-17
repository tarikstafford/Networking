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
    public var method: RequestMethod { return .get }
    public var contentType: String { return "application/json" }
    public var queryParams: [String: String]? { return nil }
    public var body: Data? { return nil }
    public var headers: [String: String]? { return nil }
    public var queryItems: [URLQueryItem]? { return nil }
    public var apiKey: String? { return nil }

}

struct APIFailedResponse: Codable {
    var message: String
}
