//
//  DefaultNewsModel.swift
//  SimpleNewsViewer
//
//  Created by Sergey on 10/03/2020.
//  Copyright © 2020 Sergey. All rights reserved.
//

import Foundation
import CoreData
import RxSwift

class DefaultNewsModel: NSObject, NewsModel {
    //MARK: - Properties
    private let loader: NewsAPI
    var allChannels: [NewsChannel] {
        let context = persistentContainer.viewContext
        let request: NSFetchRequest<ManagedNewsChannel> = ManagedNewsChannel.fetchRequest()
        request.sortDescriptors = [NewsChannelSort.name.sortDescriptor(asc: true)]
        do {
            return try context.fetch(request)
        } catch let error as NSError {
            print("Failed to fetch channels. \(error) \(error.userInfo)")
            return []
        }
    }
    var lastArticleForEnabledChannels: NewsArticle? {
        let context = persistentContainer.viewContext
        let request: NSFetchRequest<ManagedNewsArticle> = ManagedNewsArticle.fetchRequest()
        request.sortDescriptors = [NewsArticleSort.date.sortDescriptor(asc: false)]
        do {
            let enabledChannels = allChannels.filter { $0.isEnabled }
            request.predicate = NSPredicate(format: "sourceID IN %@", enabledChannels.map { $0.id } )
            let articlesForEnabledChannels = try context.fetch(request)
            return articlesForEnabledChannels.first
        } catch let error as NSError {
            print("Failed to fetch last article. \(error) \(error.userInfo)")
            return nil
        }
    }
    // MARK: - Core Data stack
    private var persistentContainer: NSPersistentContainer
    
    //MARK: - Singleton
    static var shared: DefaultNewsModel = {
        let loader = NewsLoader()
        let instance = DefaultNewsModel(with: loader)
        return instance
    }()
    
    private init(with loader: NewsAPI) {
        self.loader = loader
        persistentContainer = NSPersistentContainer(name: "SimpleNewsViewer")
        super.init()
        persistentContainer.loadPersistentStores(completionHandler: { [weak self] (storeDescription, error) in
            self?.persistentContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
//        deleteAllData(ManagedNewsChannel.entity().name!)
//        deleteAllData(ManagedNewsArticle.entity().name!)
    }
    
    //MARK: - NewsModel
    func set(channel: NewsChannel, enabled: Bool) {
        let context = persistentContainer.viewContext
        let request: NSFetchRequest<ManagedNewsChannel> = ManagedNewsChannel.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", channel.id)
        do {
            let savedChannels = try context.fetch(request)
            if let channel = savedChannels.first {
                channel.isEnabled = enabled
                saveContext()
            } else {
                print("Unknown channel \(channel)")
            }
        } catch let error as NSError {
            print("Failed to set channel \(channel.name) enabled. \(error) \(error.userInfo)")
        }
    }
    
    func set(article: NewsArticle, isRead: Bool) {
        let context = persistentContainer.viewContext
        let request: NSFetchRequest<ManagedNewsArticle> = ManagedNewsArticle.fetchRequest()
        if let url = article.url {
            request.predicate = NSPredicate(format: "url == %@", url.absoluteString)
        } else {
            request.predicate = NSPredicate(format: "title == %@", article.title)
        }
        do {
            let savedArticles = try context.fetch(request)
            if let article = savedArticles.first {
                article.isRead = isRead
                saveContext()
            } else {
                print("Unknown article \(article)")
            }
        } catch let error as NSError {
            print("Failed to set article \(article.url?.description ?? article.title) isRead. \(error) \(error.userInfo)")
        }
    }
    
    func unreadCounter(forChannels withIDs: [String]) -> Int {
        let context = self.persistentContainer.viewContext
        let articlesRequest: NSFetchRequest<ManagedNewsArticle> = ManagedNewsArticle.fetchRequest()
        articlesRequest.predicate = NSPredicate(format: "(sourceID IN %@) AND (isRead == NO)", withIDs)
        do {
            return try context.count(for: articlesRequest)
        } catch let error as NSError {
            print("Failed to fetch unread articles. \(error) \(error.userInfo)")
            return 0
        }
    }
    
    func markAsRead(articles fromChannels: [String]) {
        let context = self.persistentContainer.viewContext
        let articlesRequest = ManagedNewsArticle.batchUpdateRequest()
        articlesRequest.predicate = NSPredicate(format: "sourceID IN %@", fromChannels)
        articlesRequest.propertiesToUpdate = [(\ManagedNewsArticle.isRead).toString : true]
        articlesRequest.resultType = .updatedObjectIDsResultType
        do {
            let result = try context.execute(articlesRequest) as? NSBatchUpdateResult
            let objectIDArray = result?.result as? [NSManagedObjectID]
            let changes = [NSUpdatedObjectsKey : objectIDArray]
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes as [AnyHashable : Any], into: [persistentContainer.viewContext])
            saveContext()
        } catch let error as NSError {
            print("Failed to fetch articles. \(error) \(error.userInfo)")
        }
    }
    
    func fetchArticles(fromChannels withIDs: [NewsChannel.UID], with completion: @escaping (Result<[NewsArticle], NewsModelError>) -> Void) {
        loader.loadArticles(fromChannels: withIDs) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                let context = self.persistentContainer.viewContext
                let channelsRequest: NSFetchRequest<ManagedNewsChannel> = ManagedNewsChannel.fetchRequest()
                channelsRequest.predicate = NSPredicate(format: "id IN %@", withIDs)
                let articlesRequest: NSFetchRequest<ManagedNewsArticle> = ManagedNewsArticle.fetchRequest()
                articlesRequest.predicate = NSPredicate(format: "sourceID IN %@", withIDs)
                
                var savedChannels: [ManagedNewsChannel] = []
                var savedArticles: [ManagedNewsArticle] = []
                do {
                    savedChannels = try context.fetch(channelsRequest)
                    savedArticles = try context.fetch(articlesRequest)
                } catch let error as NSError {
                    print("Failed to fetch channels or articles. \(error) \(error.userInfo)")
                }
                
                let newResult = result
                    .map ({ articleDTOs -> [NewsArticle] in
                        self.update(articles: &savedArticles, channels: savedChannels, from: articleDTOs)
                    })
                    .mapError { NewsModelError.init(with: $0) }
                    
                self.saveContext()
                completion(newResult)
            }
        }
    }
    
    func fetchArticles(with keywords: String, with completion: @escaping (Result<[NewsArticle], NewsModelError>) -> Void) {
        loader.loadArticles(with: keywords) { result in
            let newResult = result
            .map { articleDTOs -> [NewsArticle] in
                return articleDTOs.map { DefaultNewsArticle.init(with: $0) }
            }
            .mapError { NewsModelError.init(with: $0) }
                
            DispatchQueue.main.async {
                completion(newResult)
            }
        }
    }
    
    func articles(withKeywords keywords: String) -> Single<[NewsArticle]> {
        loader.articles(withKeywords: keywords)
            .flatMap({ (articleDTOs) -> Single<[NewsArticle]> in
                Single.just(articleDTOs.map { DefaultNewsArticle.init(with: $0) })
            })
            .catchError({ (error) -> Single<[NewsArticle]> in
                if let error = error as? NewsAPIError {
                    throw NewsModelError.init(with: error)
                }
                throw error
            })
    }
    
    func fetchArticlesFromEnabledChannels(completion: @escaping (Result<[NewsArticle], NewsModelError>) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let context = self.persistentContainer.viewContext
            let request: NSFetchRequest<ManagedNewsChannel> = ManagedNewsChannel.fetchRequest()
            request.sortDescriptors = [NewsChannelSort.name.sortDescriptor(asc: true)]
            request.predicate = NSPredicate(format: "isEnabled == YES")
            do {
                let enabledChannels = try context.fetch(request)
                let uids = enabledChannels.map { $0.id }
                self.fetchArticles(fromChannels: uids, with: completion)
            } catch let error as NSError {
                print("Failed to fetch enabled channels. \(error) \(error.userInfo)")
                //TODO: add core data error type
                let result = Result<[NewsArticle], NewsModelError>.failure(NewsModelError.network)
                completion(result)
            }
        }
    }
    
    func fetchAllChannels(with completion: @escaping (Result<[NewsChannel], NewsModelError>) -> Void) {
        loader.loadNewsChannels { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                let context = self.persistentContainer.viewContext
                let request: NSFetchRequest<ManagedNewsChannel> = ManagedNewsChannel.fetchRequest()
                request.sortDescriptors = [NewsChannelSort.name.sortDescriptor(asc: true)]
                
                let newResult = result
                    .map { channelsDTO -> [NewsChannel] in
                        var savedChannels: [ManagedNewsChannel] = []
                        do {
                            savedChannels = try context.fetch(request)
                        } catch let error as NSError {
                            print("Failed to fetch channels. \(error) \(error.userInfo)")
                        }
                        
                        for channelDTO in channelsDTO {
                            if let duplicate = savedChannels.first(where: { $0.id == channelDTO.id }) {
                                //Update
                                duplicate.about = channelDTO.description
                                duplicate.name = channelDTO.name
                            } else {
                                //Insert
                                //TODO: sort array after adding all new channels
                                savedChannels.append(ManagedNewsChannel(with: channelDTO, isEnabled: false, context: context))
                            }
                        }
                        return savedChannels
                    }
                    .mapError { NewsModelError.init(with: $0) }
                
                    self.saveContext()
                    completion(newResult)
            }
        }
    }
    
    func channels(sortedBy sort: NewsChannelSort, ascending: Bool) -> NSFetchedResultsController<NewsChannel> {
        let frc = ManagedNewsChannel.fetchedResultsController(with: persistentContainer.viewContext,
                                                              sortDescriptors: [sort.sortDescriptor(asc: ascending)])
        return frc as! NSFetchedResultsController<NewsChannel>
    }
    
    func articles(for channels: [NewsChannel], sortedBy sort: NewsArticleSort, ascending: Bool) -> NSFetchedResultsController<NewsArticle> {
        let frc = ManagedNewsArticle.fetchedResultsController(with: persistentContainer.viewContext,
                                                              sortDescriptors: [sort.sortDescriptor(asc: ascending)])
        frc.fetchRequest.predicate = NSPredicate(format: "sourceID IN %@", channels.map { $0.id } )
        return frc as! NSFetchedResultsController<NewsArticle>
    }
}

//MARK: - Private methods
private extension DefaultNewsModel {
    // MARK: Core Data Saving support
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

    func deleteAllData(_ entity:String) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        fetchRequest.returnsObjectsAsFaults = false
        do {
            let results = try persistentContainer.viewContext.fetch(fetchRequest)
            for object in results {
                guard let objectData = object as? NSManagedObject else {continue}
                persistentContainer.viewContext.delete(objectData)
            }
        } catch let error {
            print("Detele all data in \(entity) error :", error)
        }
    }
    
    func update(articles: inout [ManagedNewsArticle], channels: [ManagedNewsChannel], from dtos: [NewsArticleDTO]) -> [NewsArticle] {
        for articleDTO in dtos {
            if let duplicate = articles.first(where: {
                if let url = $0.url, let urlDTO = articleDTO.url.toInternetURL {
                    return url == urlDTO
                } else {
                    return false
                }
            }) {
                //Update
                duplicate.author = articleDTO.author
                duplicate.title = articleDTO.title ?? ""
                duplicate.publishedAt = articleDTO.publishedAt
                duplicate.content = articleDTO.description
                duplicate.imageURL = articleDTO.urlToImage?.toInternetURL
                duplicate.url = articleDTO.url.toInternetURL
            } else {
                //Insert
                let article = ManagedNewsArticle(with: articleDTO, context: persistentContainer.viewContext)
                articles.append(article)
            }
        }
        
        articles.sort { article1, article2 -> Bool in
            return article1.publishedAt > article2.publishedAt
        }
        //Update channels
        for channel in channels {
            if let lastArticle = articles.first(where: { $0.sourceID == channel.id }) {
                channel.lastArticle = lastArticle
            }
        }
        return articles
    }
}

//MARK: - Private nested types
private extension DefaultNewsModel {
    @objc(DefaultNewsArticle)
    class DefaultNewsArticle: NSObject, NewsArticle {
        let title: String
        let author: String?
        let publishedAt: Date
        let content: String?
        let imageURL: URL?
        let sourceID: String?
        let url: URL?
        var isRead: Bool
        
        init(with dto: NewsArticleDTO) {
            self.title = dto.title ?? ""
            self.author = dto.author
            self.publishedAt = dto.publishedAt
            self.content = dto.description
            self.sourceID = dto.source.id
            self.imageURL = dto.urlToImage?.toInternetURL
            self.url = dto.url.toInternetURL
            self.isRead = true
        }
    }
}

//MARK: -
private extension ManagedNewsChannel {
    convenience init(with dto: NewsChannelDTO, isEnabled: Bool, context: NSManagedObjectContext) {
        self.init(context: context)
        self.about = dto.description
        self.id = dto.id
        self.name = dto.name
    }
}

//MARK: -
private extension ManagedNewsArticle {
    convenience init(with dto: NewsArticleDTO, context: NSManagedObjectContext) {
        self.init(context: context)
        self.title = dto.title ?? ""
        self.author = dto.author
        self.publishedAt = dto.publishedAt
        self.content = dto.description
        self.sourceID = dto.source.id
        self.imageURL = dto.urlToImage?.toInternetURL
        self.url = dto.url.toInternetURL
        self.isRead = false
    }
}

//MARK: -
private extension NewsModelError {
    init(with error: NewsAPIError) {
        switch error {
        case .decoding:
            self = .decoding
        case .invalidAPIKey,
             .invalidParameters,
             .server,
             .resultLimit:
            self = .server
        case .network:
            self = .network
        }
    }
}

//MARK: -
private extension NewsChannelSort {
    func sortDescriptor(asc:Bool) -> NSSortDescriptor {
      switch self{
      case .name: return NSSortDescriptor(keyPath: \ManagedNewsChannel.name, ascending: asc)
      }
    }
}

private extension NewsArticleSort {
    func sortDescriptor(asc:Bool) -> NSSortDescriptor {
      switch self{
      case .date: return NSSortDescriptor(keyPath: \ManagedNewsArticle.publishedAt, ascending: asc)
      }
    }
}
