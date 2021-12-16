//
//  APIClient.swift
//  RebtelDialConcept
//
//  Created by Tarik Stafford on 17/12/18.
//  Copyright © 2018 Tarik Stafford. All rights reserved.
//

import Foundation
import Combine

typealias CompletionHandler<Value> = (ResultType<Value>) -> Void
typealias CompletionError = (Error?) -> Void
typealias CompletionGenericType<Value> = (Value?) -> Void

public typealias ResultCompletion<T: Codable> = (Result<T, APIErrorHandler>) -> Void
public typealias StatusResultCompletion = (Result<ResponseStatus, APIErrorHandler>) -> Void

private let clientPrintKey = "🦄: "

enum ResultType<Value> {
    case response(Value)
    case error(Error)
}

public protocol APIClient {
    var token: String? { get set }
    
    var baseUrlComponents: URLComponents { get }
    
    var session: URLSession { get }
    
    func getToken() -> String?
    
    func buildRequest(for request: APIRequest, token: String) -> URLRequest?
    
    func buildUrl(for request: APIRequest) -> URL?
    
    func send<T: Codable>(_ request: APIRequest, completion: @escaping (Result<T, APIErrorHandler>) -> Void) -> URLSessionDataTask?
}

public extension APIClient {
    
    func getToken() -> String? {
        guard let token = token else { return nil }
        
        return token
    }
    
    // Construct the URL then the API Request
    func buildRequest(for request: APIRequest, token: String?) -> URLRequest? {
        guard let url = buildUrl(for: request) else {
            return nil
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.httpMethod.rawValue.uppercased()
        urlRequest.httpBody = request.httpBody
        if let token = token {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        request.headers?.forEach({ urlRequest.setValue($1, forHTTPHeaderField: $0) })
        
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")  // the request is JSON
        
        print(clientPrintKey + "URL REQUEST \n \(url)")
        
        return urlRequest
    }
    
    func buildUrl(for request: APIRequest) -> URL? {
        guard   let baseUrl = baseUrlComponents.url,
            var components = URLComponents(url: baseUrl, resolvingAgainstBaseURL: true)
            else {
                return nil
        }
        
        if let path = request.path {
            components.path = baseUrlComponents.path.appending(path)
        }
        
        components.queryItems = request.queryItems
        
        return components.url
    }
    
    @discardableResult
    func send<T: Codable>(_ request: APIRequest) -> AnyPublisher<T, Error>? {
        
        guard let urlRequest = buildRequest(for: request, token: getToken()) else {
            return nil
        }
        
        let cancellable = session
            .dataTaskPublisher(for: urlRequest)
            .tryMap { element -> Data in
                guard let httpResponse = element.response as? HTTPURLResponse,
                    httpResponse.statusCode == 200 else {
                        throw URLError(.badServerResponse)
                    }
                return element.data
            }
            .decode(type: T.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
        
        return cancellable
    }
}
