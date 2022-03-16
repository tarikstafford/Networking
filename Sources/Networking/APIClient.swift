//
//  APIClient.swift
//  RebtelDialConcept
//
//  Created by Tarik Stafford on 17/12/18.
//  Copyright © 2018 Tarik Stafford. All rights reserved.
//

import Foundation
import Combine

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
    
    func buildRequest(_ request: Request) -> URLRequest?
    
    func buildUrl(_ request: Request) -> URL?
    
    func send<T: Codable>(_ request: Request) -> AnyPublisher<T, NetworkRequestError>
    
    func send(_ request: Request) -> AnyPublisher<Int, NetworkRequestError>
}

public extension APIClient {
    
    func getToken() -> String? {
        guard let token = token else { return nil }
        
        return token
    }
    
    /// Parses a HTTP StatusCode and returns a proper error
    /// - Parameter statusCode: HTTP status code
    /// - Returns: Mapped Error
    private func httpError(_ statusCode: Int) -> NetworkRequestError {
        switch statusCode {
        case 400: return .badRequest
        case 401: return .unauthorized
        case 403: return .forbidden
        case 404: return .notFound
        case 402, 405...499: return .error4xx(statusCode)
        case 500: return .serverError
        case 501...599: return .error5xx(statusCode)
        default: return .unknownError
        }
    }
    /// Parses URLSession Publisher errors and return proper ones
    /// - Parameter error: URLSession publisher error
    /// - Returns: Readable NetworkRequestError
    private func handleError(_ error: Error) -> NetworkRequestError {
        switch error {
        case is Swift.DecodingError:
            return .decodingError
        case let urlError as URLError:
            return .urlSessionFailed(urlError)
        case let error as NetworkRequestError:
            return error
        default:
            return .unknownError
        }
    }
    
    func buildRequest(_ request: Request) -> URLRequest? {
        guard let url = buildUrl(request) else {
            return nil
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue.uppercased()
        urlRequest.httpBody = request.body
        urlRequest.cachePolicy = request.cacheProtocol
        if let token = getToken() {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        request.headers?.forEach({ urlRequest.setValue($1, forHTTPHeaderField: $0) })
        
        urlRequest.setValue(request.contentType, forHTTPHeaderField: "Content-Type")
        
        networkLogger(text: "URL \n \(url)")
        networkLogger(text: "URL REQUEST \n \(urlRequest)")
        
        return urlRequest
    }
    
    func buildUrl(_ request: Request) -> URL? {
        guard var baseUrl = baseUrlComponents.url else {
            return nil
        }
        
        if let path = request.path {
            baseUrl.appendPathComponent(path)
        }
        
        guard var components = URLComponents(url: baseUrl, resolvingAgainstBaseURL: true) else { return nil }
        
        components.queryItems = request.queryItems
        
        return components.url
    }
    
    @discardableResult
    func send<T: Codable>(_ request: Request) -> AnyPublisher<T, NetworkRequestError> {
        
        guard let urlRequest = buildRequest(request) else {
            return Fail(outputType: T.self, failure: NetworkRequestError.badRequest).eraseToAnyPublisher()
        }
        
        let cancellable = session
            .dataTaskPublisher(for: urlRequest)
            .tryMap { element -> Data in
                
                guard let response = element.response as? HTTPURLResponse else {
                    throw NetworkRequestError.badRequest
                }
                
                guard (200...299).contains(response.statusCode) else {
                    throw httpError(response.statusCode)
                }
                
                let str = String(decoding: element.data, as: UTF8.self)
                networkLogger(text: str)
                return element.data
            }
            .decode(type: T.self, decoder: JSONDecoder())
            .mapError {
                handleError($0)
            }
            .eraseToAnyPublisher()
        
        return cancellable
    }
    
    @discardableResult
    func send(_ request: Request) -> AnyPublisher<Int, NetworkRequestError> {
        
        guard let urlRequest = buildRequest(request) else {
            return Fail(outputType: Int.self, failure: NetworkRequestError.badRequest).eraseToAnyPublisher()
        }
        
        let cancellable = session
            .dataTaskPublisher(for: urlRequest)
            .tryMap { element -> Int in
                
                guard let response = element.response as? HTTPURLResponse else {
                    throw NetworkRequestError.badRequest
                }
                
                guard (200...299).contains(response.statusCode) else {
                    throw httpError(response.statusCode)
                }
                
                let str = String(decoding: element.data, as: UTF8.self)
                networkLogger(text: str)
                return response.statusCode
            }
            .mapError {
                handleError($0)
            }
            .eraseToAnyPublisher()
        
        return cancellable
    }
    
    func networkLogger(text: String) {
        print(clientPrintKey + " " + text)
    }
}
