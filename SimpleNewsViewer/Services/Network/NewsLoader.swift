//
//  NewsLoader.swift
//  SimpleNewsViewer
//
//  Created by Sergey on 15/03/2020.
//  Copyright © 2020 Sergey. All rights reserved.
//

import Foundation
import RxSwift

class NewsLoader: NewsAPI {
    //MARK: Properties
    private let urlSession = URLSession.shared
    private var lastRequest: URLRequest?
    
    //MARK: Public methods
    func loadNewsChannels(completion: @escaping (Result<[NewsChannelDTO], NewsAPIError>) -> Void) {
        let request = NewsRouter.sources.asURLRequest()
        load(from: request, completion: completion)
    }
    
    func loadArticles(fromChannels withIDs: [NewsChannel.UID], completion: @escaping (Result<[NewsArticleDTO], NewsAPIError>) -> Void) {
        let channelsUIDs = withIDs.joined(separator: ",")
        let request = NewsRouter.everything(sources: channelsUIDs).asURLRequest()
        load(from: request, completion: completion)
    }
    
    func loadArticles(with keywords: String, completion: @escaping (Result<[NewsArticleDTO], NewsAPIError>) -> Void) {
        let request = NewsRouter.search(keywords: keywords).asURLRequest()
        if let lastRequest = lastRequest {
            cancel(request: lastRequest)
        }
        lastRequest = request
        load(from: request, completion: completion)
    }
    //Rx
    func articles(withKeywords keywords: String) -> Single<[NewsArticleDTO]> {
        let request = NewsRouter.search(keywords: keywords).asURLRequest()
        return load(from: request)
    }
    
    //MARK: Private methods
    private func decode<Payload: Decodable>(data: Data) -> Result<Payload, NewsAPIError> {
        let result = Result.init { () -> Payload in
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let codingData = try decoder.decode(Response<Payload>.self, from: data)
            switch codingData {
            case .success(let payload):
                return payload
            case .error(let code, let message):
                print("decode error with code: \"\(code)\" message: \"\(message)\"")
                switch code {
                case C.invalidAPIKeyCode:
                    throw NewsAPIError.invalidAPIKey
                case C.invalidParameterCode:
                    throw NewsAPIError.invalidParameters
                case C.developerAccountLimitCode:
                    throw NewsAPIError.resultLimit
                default:
                    throw NewsAPIError.server(code: code, message: message)
                }
            }
        }.mapError { (error) -> NewsAPIError in
            print(error)
            return (error is NewsAPIError) ? error as! NewsAPIError : .decoding
        }
        
        return result
    }
    //Rx
    private func decode<Payload: Decodable>(data: Data) throws -> Payload {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let codingData = try decoder.decode(Response<Payload>.self, from: data)
        switch codingData {
        case .success(let payload):
            return payload
        case .error(let code, let message):
            print("decode error with code: \"\(code)\" message: \"\(message)\"")
            switch code {
            case C.invalidAPIKeyCode:
                throw NewsAPIError.invalidAPIKey
            case C.invalidParameterCode:
                throw NewsAPIError.invalidParameters
            case C.developerAccountLimitCode:
                throw NewsAPIError.resultLimit
            default:
                throw NewsAPIError.server(code: code, message: message)
            }
        }
    }
    
    private func load<Payload: Decodable>(from request: URLRequest, completion: @escaping (Result<Payload, NewsAPIError>) -> Void) {
        let task = urlSession.dataTask(with: request) { [weak self] (data, response, error) in

            var result = Result<Payload, NewsAPIError>.failure(NewsAPIError.network)
            defer {
                if let urlError = error as? URLError,
                urlError.code.rawValue == URLError.cancelled.rawValue  {
                } else {
                    completion(result)
                }
            }
            
            guard let data = data, let self = self, error == nil else { return }
            
            result = self.decode(data: data)
        }
        task.resume()
    }
    //Rx
    private func load<Payload: Decodable>(from request: URLRequest) -> Single<Payload> {
        return Single<Payload>.create { single in
            let task = self.urlSession.dataTask(with: request) { (data, response, error) in
                if error != nil {
                    print("urlError.code.rawValue \((error as? URLError)?.code.rawValue)")
                    print("URLError.cancelled.rawValue \(URLError.cancelled.rawValue)")
                    single(.error(NewsAPIError.network))
                } else {
                    do {
                        let data = data ?? Data()
                        let result: Payload = try self.decode(data: data)
                        single(.success(result))
                    } catch let error {
                        let error = error is NewsAPIError ? error as! NewsAPIError : .decoding
                        single(.error(error))
                    }
                }
            }
            task.resume()
            return Disposables.create {
                task.cancel()
            }
        }
    }

    private func cancel(request: URLRequest) {
        urlSession.getAllTasks { (tasks) in
            tasks.filter {$0.originalRequest?.url == request.url}
                .forEach {$0.cancel()}
        }
    }
}

//MARK: - Private nested types
private extension NewsLoader {
    enum Response<Payload: Decodable>
    {
        enum CodingKeys: String, CodingKey
        {
            case status
            case code
            case message
            case sources
            case articles
        }
        
        case success(Payload)
        case error(code: String, message: String)
    }
    
    struct C {
        static let statusOk = "ok"
        static let invalidAPIKeyCode = "apiKeyInvalid"
        static let invalidParameterCode = "parametersMissing"
        static let developerAccountLimitCode = "maximumResultsReached"
    }
}

extension NewsLoader.Response: Decodable {
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let status = try c.decode(String.self, forKey: .status)
        
        if status == NewsLoader.C.statusOk {
            self = .success(try c.decode(Payload.self, forKey: try Self.payloadField()))
        } else {
            self = .error(code: try c.decode(String.self, forKey: .code),
                          message: try c.decode(String.self, forKey: .message))
        }
    }

    private static func payloadField() throws -> CodingKeys
    {
        switch Payload.self
        {
            case is [NewsChannelDTO].Type : return .sources
            case is [NewsArticleDTO].Type : return .articles
            default:                        throw NewsAPIError.decoding
        }
    }
}
