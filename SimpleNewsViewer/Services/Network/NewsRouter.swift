//
//  NewsRouter.swift
//  SimpleNewsViewer
//
//  Created by Sergey on 15/03/2020.
//  Copyright © 2020 Sergey. All rights reserved.
//

import Foundation

enum NewsRouter {
    case sources
    case everything(sources: String, page: Int = 1, pageSize: Int = 100)
    case search(keywords: String, page: Int = 1, pageSize: Int = 100)
}

private extension NewsRouter {
    
    var path: String {
        switch self {
        case .sources:
            return "/v2/sources"
        case .everything,
             .search:
            return "/v2/everything"
        }
    }
    
    var parameters: [String : String] {
        switch self {
        case .sources:
            return [:]
        case .everything(let sources, let page, let pageSize):
            return [
                "sources" : sources,
                "page" : "\(page)",
                "pageSize" : "\(pageSize)"
            ]
        case .search(let keywords, let page, let pageSize):
            return [
                "q" : keywords,
                "page" : "\(page)",
                "pageSize" : "\(pageSize)"
            ]
            
        }
    }
}

extension NewsRouter {
    
    func asURLRequest() -> URLRequest {
        switch self {
        default:
            var components = URLComponents()
            components.scheme = Constants.scheme
            components.host = Constants.host
            components.path = path
            components.queryItems = parameters.compactMap { URLQueryItem(name: $0.key, value: $0.value) }
            
            guard let url = components.url else {
                preconditionFailure("Failed to construct URL")
            }
            var request = URLRequest(url: url, timeoutInterval: Constants.timeInterval)
            request.setValue(Constants.httpAPIKeyHeaderValue, forHTTPHeaderField: Constants.httpAPIKeyHeaderField)
            return request
        }
    }
}

private extension NewsRouter {
    enum Constants {
        static let scheme = "https"
        static let host = "newsapi.org"
        static let httpAPIKeyHeaderField = "X-Api-Key"
        static let httpAPIKeyHeaderValue = "8d903c76d5624851ba917e6c2fcec07e"
        static let timeInterval = TimeInterval(120)
    }
}

