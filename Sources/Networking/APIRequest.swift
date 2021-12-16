//
//  APIClient.swift
//  RebtelDialConcept
//
//  Created by Tarik Stafford on 17/12/18.
//  Copyright © 2018 Tarik Stafford. All rights reserved.
//

import Foundation

public protocol APIRequest {
    var headers: [String:String]? { get }
    var httpBody: Data? { get }
    var httpMethod: RequestMethod { get }
    var path: String? { get }
    var queryItems: [URLQueryItem]? { get }
    var apiKey: String? { get }
    
    func localizedErrorDescription(statusCode: ResponseStatus) -> String?
}

struct APIFailedResponse: Codable {
    var message: String
}
