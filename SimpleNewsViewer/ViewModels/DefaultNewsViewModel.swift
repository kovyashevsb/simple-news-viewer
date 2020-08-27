//
//  DefaultNewsViewModel.swift
//  SimpleNewsViewer
//
//  Created by Sergey on 16/06/2020.
//  Copyright © 2020 Sergey. All rights reserved.
//

import Foundation
import CoreData

final class DefaultNewsViewModel: NSObject, NewsViewModel {
    private enum Mode {
        case channel(NewsChannel)
        case enabledChannels
    }
    //MARK: - Properties
    private let mode: Mode
    private var articles: [NewsArticle] = []
    private let newsModel: NewsModel = DefaultNewsModel.shared
    private var error: NewsModelError?
    private let fetchedResultsController: NSFetchedResultsController<NewsArticle>

    //MARK: - Initializers
    private init(mode: Mode) {
        self.mode = mode
                
        switch mode {
        case .channel(let channel):
            fetchedResultsController = newsModel.articles(for: [channel], sortedBy: .date, ascending: false)
        case .enabledChannels:
            let enabledChannels = newsModel.allChannels.filter { $0.isEnabled }
            fetchedResultsController = newsModel.articles(for: enabledChannels, sortedBy: .date, ascending: false)
        }
        super.init()
        
        fetchedResultsController.delegate = self

        do {
            try self.fetchedResultsController.performFetch()
            articles = fetchedResultsController.fetchedObjects ?? []
        } catch let error as NSError {
            print("DefaultNewsViewModel refresh() failed to fetch data \(error): \(error.userInfo)")
        }
    }
    
    static func singeChannelViewModel(channel:NewsChannel) -> NewsViewModel {
        return DefaultNewsViewModel(mode: Mode.channel(channel))
    }
    static func allChannelsViewModel() -> NewsViewModel {
        return DefaultNewsViewModel(mode: Mode.enabledChannels)
    }
    
    //MARK: - NewsViewModel
    var state: NewsViewModelState {
        if let error = error {
            return .failure(error: error)
        }
        if articles.isEmpty {
            switch mode {
            case .channel(let channel):
                let formatMessage = NSLocalizedString("No news in the channel %@", comment: "")
                let message = String.localizedStringWithFormat(formatMessage, channel.name)
                return .noItems(message: message)
            case .enabledChannels:
                let message = NSLocalizedString("No news in the favorite channels", comment: "")
                return .noItems(message: message)
            }
        } else {
            return .items(items: articles.map{ NewsViewModelState.Item(article: $0) } )
        }
    }
    var onLoading: ((Bool) -> Void)?
    var onChangeState: ((NewsViewModelState) -> Void)?
    
    func refresh() {
        let completion: (Result<[NewsArticle], NewsModelError>) -> Void = { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success:
                self.error = nil
            case .failure(let error):
                self.error = error
            }
            
            if let onLoading = self.onLoading {
                onLoading(false)
            }
        }
        
        if let onLoading = self.onLoading {
            onLoading(true)
        }
        switch mode {
        case .channel(let channel):
            newsModel.fetchArticles(fromChannels: [channel.id], with: completion)
        case .enabledChannels:
            newsModel.fetchArticlesFromEnabledChannels(completion: completion)
        }
    }
    
    func markAsRead() {
        switch mode {
        case .channel(let channel):
            newsModel.markAsRead(articles: [channel.id])
        case .enabledChannels:
            let enabledChannelsIDs = newsModel.allChannels.filter { $0.isEnabled }.map { $0.id }
            newsModel.markAsRead(articles: enabledChannelsIDs)
        }
    }
    
    func markAsRead(article withUrl: URL) {
        if let article = articles.first(where: { $0.url == withUrl }) {
            newsModel.set(article: article, isRead: true)
        }
    }
}

//MARK: - NSFetchedResultsControllerDelegate
extension DefaultNewsViewModel: NSFetchedResultsControllerDelegate {
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        articles = fetchedResultsController.fetchedObjects ?? []
        if let onChangeState = onChangeState {
            onChangeState(state)
        }
    }
}


private extension NewsViewModelState.Item {
    init(article: NewsArticle) {
        self.title = article.title
        self.author = article.author
        self.publishedAt = article.publishedAt
        self.description = article.content
        self.imageURL = article.imageURL
        self.url = article.url
        self.isRead = article.isRead
    }
}
