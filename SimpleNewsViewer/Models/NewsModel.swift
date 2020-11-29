//
//  NewsModel.swift
//  SimpleNewsViewer
//
//  Created by Sergey on 17/03/2020.
//  Copyright © 2020 Sergey. All rights reserved.
//

import Foundation
import CoreData
import RxSwift

enum NewsModelError: Error {
    case network
    case server
    case decoding
}

enum NewsChannelSort {
    case name
}

enum NewsArticleSort {
    case date
}

protocol NewsModel {
    /// Use in main thread only
    var allChannels: [NewsChannel] { get }
    /// Use in main thread only
    var lastArticleForEnabledChannels: NewsArticle? { get }
    /// Use in main thread only
    func set(channel: NewsChannel, enabled: Bool)
    /// Use in main thread only
    func set(article: NewsArticle, isRead: Bool)
    /// Use in main thread only
    func unreadCounter(forChannels withIDs: [NewsChannel.UID]) -> Int
    /// Use in main thread only
    func markAsRead(articles fromChannels: [NewsChannel.UID])
    
    /// Calling completion in main thread
    func fetchAllChannels(with completion: @escaping (Result<[NewsChannel], NewsModelError>) -> Void)
    
    /// Calling completion in main thread
    func fetchArticles(fromChannels withIDs: [NewsChannel.UID], with completion: @escaping (Result<[NewsArticle], NewsModelError>) -> Void)
    /// Calling completion in main thread
    func fetchArticlesFromEnabledChannels(completion: @escaping (Result<[NewsArticle], NewsModelError>) -> Void)
    /// Calling completion in main thread
    func fetchArticles(with keywords: String, with completion: @escaping (Result<[NewsArticle], NewsModelError>) -> Void)
    
    func channels(sortedBy sort:NewsChannelSort, ascending: Bool) -> NSFetchedResultsController<NewsChannel>
    func articles(for channels:[NewsChannel], sortedBy sort:NewsArticleSort, ascending: Bool) -> NSFetchedResultsController<NewsArticle>
    
    //Rx
    func articles(withKeywords keywords: String) -> Single<[NewsArticle]>
}
