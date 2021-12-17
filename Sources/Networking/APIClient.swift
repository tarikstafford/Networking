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
    
    func buildRequest<T: APIRequest>(_ request: T) -> URLRequest?
    
    func buildUrl<T: APIRequest>(_ request: T) -> URL?
    
    func send<T: APIRequest>(_ request: T) -> AnyPublisher<T.ReturnType, NetworkRequestError>
}

public extension APIClient {
    
    func getToken() -> String? {
        guard let token = token else { return nil }
        
        return token
    }
    
    // Construct the URL then the API Request
    func buildRequest<T: APIRequest>(_ request: T) -> URLRequest? {
        guard let url = buildUrl(request) else {
            return nil
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue.uppercased()
        urlRequest.httpBody = request.body
        if let token = getToken() {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        request.headers?.forEach({ urlRequest.setValue($1, forHTTPHeaderField: $0) })
        
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")  // the request is JSON
        
        print(clientPrintKey + "URL REQUEST \n \(url)")
        
        return urlRequest
    }
    
    func buildUrl<T: APIRequest>(_ request: T) -> URL? {
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
    
    @discardableResult
    func send<T: APIRequest>(_ request: T) -> AnyPublisher<T.ReturnType, NetworkRequestError> {
        
        guard let urlRequest = buildRequest(request) else {
            return Fail(outputType: T.ReturnType.self, failure: NetworkRequestError.badRequest).eraseToAnyPublisher()
        }
        
        let cancellable = session
            .dataTaskPublisher(for: urlRequest)
            .tryMap { element -> Data in
                if let response = element.response as? HTTPURLResponse,
                   !(200...299).contains(response.statusCode) {
                    throw httpError(response.statusCode)
                }
                return element.data
            }
            .decode(type: T.ReturnType.self, decoder: JSONDecoder())
            .mapError {
                handleError($0)
            }
            .eraseToAnyPublisher()
        
        return cancellable
    }
}
