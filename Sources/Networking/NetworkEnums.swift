//
//  NetworkEnums.swift
//  RebtelDialConcept
//
//  Created by Tarik Stafford on 17/12/18.
//  Copyright © 2018 Tarik Stafford. All rights reserved.
//

import Foundation

public enum  RequestMethod: String {
    case get, post, put, delete
}

public enum ResponseStatus: Int {
    case ok = 200
    case badRequest = 400
    case unauthorized = 401
    case forbidden = 403
    case notFound = 404
    case internalServer = 500
    case badGateway = 502
    case serviceUnavailable = 503
    case gatewayTimeout = 504
    case unhandled = -1
    
    init(code: Int) {
        switch code {
        case 200..<300:
            self = .ok
        default:
            self = ResponseStatus(rawValue: code) ?? .unhandled
        }
    }
}
