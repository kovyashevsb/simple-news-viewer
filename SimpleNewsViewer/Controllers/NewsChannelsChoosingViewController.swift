//
//  NewsChannelsChoosingViewController.swift
//  SimpleNewsViewer
//
//  Created by Sergey on 09/03/2020.
//  Copyright © 2020 Sergey. All rights reserved.
//

import UIKit
import CoreData

class NewsChannelsChoosingViewController: UIViewController {
    private enum CellData {
      case allNews(NewsArticle?, Int)
      case channel(NewsChannel, NewsArticle?, Int)
        var article: NewsArticle? {
            switch self {
            case .allNews(let article, _):    return article
            case .channel(_, let article, _): return article
            }
        }
        var unreadCounter: Int {
            switch self {
            case .allNews(_, let unreadCounter):    return unreadCounter
            case .channel(_, _, let unreadCounter): return unreadCounter
            }
        }
    }
    //MARK: - Properties
    private let newsModel: NewsModel = DefaultNewsModel.shared
    private var cells : [CellData] = []
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var errorLabel: ErrorLabel!
    @IBOutlet private weak var emptyMessageLabel: UILabel!
    private var refreshControl = UIRefreshControl()
    private lazy var fetchedResultsController = newsModel.channels(sortedBy: .name, ascending: true)
    private var needUpdateArticles = false
    
    //MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("News", comment: "")
        emptyMessageLabel.text = NSLocalizedString("Select your favorite channels!", comment: "")
        
        refreshControl.addTarget(self, action: #selector(updateChannels), for: .valueChanged)
        collectionView.refreshControl = refreshControl
        
        fetchedResultsController.fetchRequest.predicate = NSPredicate(format: "isEnabled == YES")
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print("NewsChannelsChoosingViewController failed to performFetch \(error) \(error.userInfo)")
        }
        setupCells()
        fetchEnabledChannelsWithArticles()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        // changing the orientation of the device does not always invalidate the layout
        // therefore, forcibly invalidate the layout
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    //MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let articlesVC = segue.destination as? ArticlesViewController,
            let selectedIndex = collectionView.indexPathsForSelectedItems?.first?.row {
            switch cells[selectedIndex] {
            case .allNews:
                articlesVC.set(mode: .enabledChannels)
            case .channel(let channel, _, _):
                articlesVC.set(mode: .channel(channel))
            }
        }
    }
}

//MARK: - UICollectionViewDataSource
extension NewsChannelsChoosingViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cells.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch cells[indexPath.row] {
        case .allNews(let article, let unreadCounter):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AllNewsCollectionViewCell", for: indexPath) as! AllNewsCollectionViewCell
            cell.set(lastNews: article?.content, unreadCounter: unreadCounter)
            return cell
        case .channel(let channel, let article, let unreadCounter):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NewsChannelCollectionViewCell", for: indexPath) as! NewsChannelCollectionViewCell
            cell.set(name: channel.name,
                     lastNews: article?.content,
                     imageURL: article?.imageURL,
                     unreadCounter: unreadCounter)
            return cell
        }
    }
}

//MARK: - UICollectionViewDelegateFlowLayout
extension NewsChannelsChoosingViewController: UICollectionViewDelegateFlowLayout {
    /// return amount collection view cells per row for different device orintation
    private var cellsPerRow: CGFloat {
        let minSize: CGFloat = 155
        let maxSize: CGFloat = 195
        switch UIDevice.current.orientation {
        case .landscapeLeft, .landscapeRight:
            return (collectionView.bounds.width/minSize).rounded()
        default:
            return (collectionView.bounds.width/maxSize).rounded()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let collectionWidth = collectionView.bounds.width
        let layout = collectionViewLayout as! UICollectionViewFlowLayout
        let cellsPerRow = self.cellsPerRow
        // (collectionWidth - insets)/(cellsPerRow)
        let cellWidth = (collectionWidth - layout.sectionInset.left - layout.sectionInset.right - layout.minimumInteritemSpacing*(cellsPerRow-1))/cellsPerRow
        // without rounding, cells do not fit in a row
        let roundedWidth = cellWidth.rounded(.down)

        switch cells[indexPath.row] {
        case .allNews:
            // (width: collectionWidth - insets, height: roundedWidth)
            return CGSize(width: collectionWidth - layout.sectionInset.left - layout.sectionInset.right, height: roundedWidth)
        case .channel:
            return CGSize(width: roundedWidth, height: roundedWidth)
        }
    }
}

//MARK: - private methods
private extension NewsChannelsChoosingViewController {
    /// converts channels and articles into `CellData`
    func setupCells() {
        cells = []
        let enabledChannels: [NewsChannel] = fetchedResultsController.fetchedObjects ?? []
        guard !enabledChannels.isEmpty else {
            collectionView.reloadData()
            showEmptyMessage()
            return
        }
        hideEmptyMessage()
        if enabledChannels.count > 1 {
            let lastArticle = newsModel.lastArticleForEnabledChannels
            let enabledChannelsIDs = enabledChannels.map { $0.id }
            let unreadCounter = newsModel.unreadCounter(forChannels: enabledChannelsIDs)
            cells.append(.allNews(lastArticle, unreadCounter))
        }
        enabledChannels.forEach { channel in
            let unreadCounter = newsModel.unreadCounter(forChannels: [channel.id])
            cells.append( CellData.channel(channel, channel.lastNews, unreadCounter))
        }
        collectionView.reloadData()
    }
    
    func fetchEnabledChannelsWithArticles() {
        refreshControl.beginRefreshing()
        let enabledChannels = self.newsModel.allChannels.filter { $0.isEnabled }
        guard !enabledChannels.isEmpty else {
            setupCells()
            self.refreshControl.endRefreshing()
            return
        }
        fetchLastNews { [weak self] articles in
            guard let self = self else { return }
            self.refreshControl.endRefreshing()
        }
        return
    }
    
    func fetchLastNews(with completion: @escaping ([NewsArticle])->Void) {
        newsModel.fetchArticlesFromEnabledChannels { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let lastNews):
                completion(lastNews)
                self.errorLabel.text = ""
            case .failure(let error):
                self.errorLabel.set(with: error)
                completion([])
            }
        }
    }
}

//MARK: empty data message
private extension NewsChannelsChoosingViewController {
    func showEmptyMessage() {
        emptyMessageLabel.isHidden = false
    }

    func hideEmptyMessage() {
        emptyMessageLabel.isHidden = true
    }
}

//MARK: - Observing method
private extension NewsChannelsChoosingViewController {
    @objc
    func updateChannels() {
        fetchEnabledChannelsWithArticles()
    }
}

//MARK: -
extension NewsChannelsChoosingViewController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            needUpdateArticles = true
        default:
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if needUpdateArticles {
            needUpdateArticles = false
            fetchLastNews { _ in
            }
        }
        setupCells()
        collectionView.reloadData()
    }
}
