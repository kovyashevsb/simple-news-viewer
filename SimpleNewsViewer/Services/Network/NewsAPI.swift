//
//  NewsAPI.swift
//  SimpleNewsViewer
//
//  Created by Sergey on 20/03/2020.
//  Copyright © 2020 Sergey. All rights reserved.
//

import Foundation

enum NewsAPIError: Error {
    case invalidAPIKey
    case invalidParameters
    case resultLimit
    case network
    case decoding
    case server(code:String, message:String)
}

struct NewsChannelDTO: Decodable {
    let id: String
    let name: String
    let description: String
}

struct NewsArticleDTO: Decodable {
    struct NewsChannel: Decodable {
        let id: String?
    }
    let title: String?
    let author: String?
    let publishedAt: Date
    let description: String?
    let urlToImage: String?
    let source: NewsChannel
    let url: String
}

protocol NewsAPI {
    
    func loadNewsChannels(completion: @escaping (Result<[NewsChannelDTO], NewsAPIError>) -> Void)
    func loadArticles(fromChannels withIDs: [NewsChannel.UID], completion: @escaping (Result<[NewsArticleDTO], NewsAPIError>) -> Void)
    func loadArticles(with keywords: String, completion: @escaping (Result<[NewsArticleDTO], NewsAPIError>) -> Void)
}
