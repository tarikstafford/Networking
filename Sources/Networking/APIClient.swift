//
//  APIClient.swift
//  RebtelDialConcept
//
//  Created by Tarik Stafford on 17/12/18.
//  Copyright © 2018 Tarik Stafford. All rights reserved.
//

import Foundation

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
    func buildRequest(for request: APIRequest, token: String) -> URLRequest? {
        guard let url = buildUrl(for: request) else {
            return nil
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.httpMethod.rawValue.uppercased()
        urlRequest.httpBody = request.httpBody
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        
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
    func send<T: Codable>(_ request: APIRequest, completion: @escaping (ResultCompletion<T>)) -> URLSessionDataTask? {
        
        let errorCallback: (APIErrorHandler) -> Void = {
            completion(.failure($0))
        }
        
        guard let token = getToken() else {
            errorCallback(APIErrorHandler.unauthorized)
            return nil
        }
        
        guard let urlRequest = buildRequest(for: request, token: token) else {
            errorCallback(APIErrorHandler.client)
            return nil
        }
        
        let task = session.dataTask(with: urlRequest) { (data, response, error) in
            guard let httpResponse = response as? HTTPURLResponse else { return }
            
            print(clientPrintKey + "\n \(String(describing: response))")
            
            let statusCode = ResponseStatus.init(code: httpResponse.statusCode)
            
            switch statusCode {
            case .ok:
                break
            case .unauthorized:
                errorCallback(APIErrorHandler.unauthorized)
            case .notFound:
                errorCallback(APIErrorHandler.notFound)
                return
            default:
                if let data = data {
                    let failed = try? JSONDecoder().decode(APIFailedResponse.self, from: data)
                    print(clientPrintKey + "\n \(String(describing: failed?.message))")
                }
                errorCallback(APIErrorHandler.network(request: request, statusCode: statusCode))
                return
            }
            
            guard let data = data else {
                errorCallback(APIErrorHandler.noData)
                return
            }
            
            do {
                print(data.description)
                completion(.success(try JSONDecoder().decode(T.self, from: data)))
            } catch let error {
                errorCallback(APIErrorHandler.decoding(reason: error.localizedDescription))
            }
        }
        
        defer { task.resume() }
        
        return task
    }
    
    @discardableResult
    func send(_ request: APIRequest, completion: @escaping (StatusResultCompletion)) -> URLSessionDataTask? {
        
        let errorCallback: (APIErrorHandler) -> Void = {
            completion(.failure($0))
        }
        
        guard let token = getToken() else {
            errorCallback(APIErrorHandler.unauthorized)
            return nil
        }
        
        guard let urlRequest = buildRequest(for: request, token: token) else {
            errorCallback(APIErrorHandler.client)
            return nil
        }
        
        let task = session.dataTask(with: urlRequest) { (data, response, error) in
            guard let httpResponse = response as? HTTPURLResponse else { return }
            
            print(clientPrintKey + "\n \(String(describing: response)) \n===================================")
            
            let statusCode = ResponseStatus.init(code: httpResponse.statusCode)
            
            switch statusCode {
            case .ok:
                break
            case .unauthorized:
                errorCallback(APIErrorHandler.unauthorized)
            case .notFound:
                errorCallback(APIErrorHandler.notFound)
            default:
                if let data = data {
                    let failed = try? JSONDecoder().decode(APIFailedResponse.self, from: data)
                    print(clientPrintKey + "\n \(String(describing: failed?.message))")
                }
                errorCallback(APIErrorHandler.network(request: request, statusCode: statusCode))
            }
            
            guard data != nil else {
                errorCallback(APIErrorHandler.noData)
                return
            }
            
            completion(.success(statusCode))
        }
        
        defer { task.resume() }
        
        return task
    }
}
