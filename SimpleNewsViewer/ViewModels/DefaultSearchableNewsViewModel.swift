//
//  DefaultSearchableNewsViewModel.swift
//  SimpleNewsViewer
//
//  Created by Sergey on 26/07/2020.
//  Copyright © 2020 Sergey. All rights reserved.
//

import Foundation
import RxSwift

final class DefaultSearchableNewsViewModel: SearchableNewsViewModel {
    
    private var keywords: String = ""
    private var articles: [NewsArticle] = []
    private var error: NewsModelError?
    private let newsModel: NewsModel = DefaultNewsModel.shared
    
    //MARK: - SearchableNewsViewModel
    func searchNews(withKeywords keywords: String) {
        self.keywords = keywords
        refresh()
    }
    //Rx    
    func searchArticles(withKeywords keywords: String) -> Single<NewsViewModelState> {
        if keywords.isEmpty {
            return Single.just(.noItems(message: NSLocalizedString("No results", comment: "")))
        } else {
            return newsModel.articles(withKeywords: keywords)
                .flatMap({ (articles) -> Single<NewsViewModelState> in
                    if articles.isEmpty {
                        return Single.just(.noItems(message: NSLocalizedString("No results", comment: "")))
                    } else {
                        return Single.just(.items(items: articles.map{ NewsViewModelState.Item(article: $0) }))
                    }
                })
                .catchError({ (error) -> Single<NewsViewModelState> in
                    if let error = error as? NewsModelError {
                        return Single.just(.failure(error: error))
                    }
                    throw error
                })
        }
    }

    //MARK: - NewsViewModel
        var state: NewsViewModelState {
            if let error = error {
                return .failure(error: error)
            }
            if articles.isEmpty {
                let message = NSLocalizedString("No results", comment: "")
                return .noItems(message: message)
            } else {
                return .items(items: articles.map{ NewsViewModelState.Item(article: $0) } )
            }
        }
        var onLoading: ((Bool) -> Void)?
        var onChangeState: ((NewsViewModelState) -> Void)?
        
        func refresh() {
            if let onLoading = self.onLoading {
                onLoading(true)
            }
            if !keywords.isEmpty {
                let searchCompletion: (Result<[NewsArticle], NewsModelError>) -> Void = { [weak self] result in
                            guard let self = self else { return }
                            
                            switch result {
                            case .success(let articles):
                                self.articles = articles
                                self.error = nil
                            case .failure(let error):
                                self.error = error
                            }
                            if let onChangeState = self.onChangeState {
                                onChangeState(self.state)
                            }
                            if let onLoading = self.onLoading {
                                onLoading(false)
                            }
                        }
                newsModel.fetchArticles(with: keywords, with: searchCompletion)
            } else {
                self.articles = []
                if let onChangeState = self.onChangeState {
                    onChangeState(self.state)
                }
            }
        }
    func markAsRead() {
        //Searchable articles dont save in core data
    }
    func markAsRead(article withUrl: URL) {
        //Searchable articles dont save in core data
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
