//
//  ErrorHandler.swift
//  RebtelDialConcept
//
//  Created by Tarik Stafford on 17/12/18.
//  Copyright © 2018 Tarik Stafford. All rights reserved.
//

import Foundation

public enum APIErrorHandler: Error, Equatable {
    
    case invalidUrl
    case client
    case unreachable
    case noData
    case unauthorized
    case notFound
}

extension APIErrorHandler: LocalizedError {}
