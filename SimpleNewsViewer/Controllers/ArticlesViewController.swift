//
//  ArticlesViewController.swift
//  SimpleNewsViewer
//
//  Created by Sergey on 17/03/2020.
//  Copyright © 2020 Sergey. All rights reserved.
//

import UIKit
import SafariServices

class ArticlesViewController: UIViewController {
    enum Mode {
        case channel(NewsChannel)
        case enabledChannels
    }
    //MARK: - Properties
    private var newsViewModel: NewsViewModel?
    private var items: [NewsViewModelState.Item] = []
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var errorLabel: ErrorLabel!
    @IBOutlet private weak var emptyMessageLabel: UILabel!
    private var refreshControl = UIRefreshControl()
    private var needFetchArticles: Bool = false
    private var keywords = ""
    
    //MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        let cellNib = UINib(nibName: "ArticlesTableViewCell", bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: "ArticlesTableViewCell")
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
        tableView.tableFooterView = UIView() //hide separators between empty cells

        self.updateFor(state: newsViewModel?.state)
        
        if needFetchArticles {
            refresh()
        }
    }
    
    //MARK: Public methods
    func set(mode: Mode) {
        title = mode.title

        switch mode {
        case .channel(let channel):
            newsViewModel = DefaultNewsViewModel.singeChannelViewModel(channel: channel)
        case .enabledChannels:
            newsViewModel = DefaultNewsViewModel.allChannelsViewModel()
        }
        
        newsViewModel?.onLoading = { [weak self] (isLoading) in
            guard let self = self else { return }
            if isLoading {
                self.refreshControl.beginRefreshing()
            } else {
                self.refreshControl.endRefreshing()
            }
        }
        newsViewModel?.onChangeState = { [weak self] (state) in
            guard let self = self else { return }
            self.updateFor(state: state)
        }
        
        guard isViewLoaded else {
            needFetchArticles = true
            return
        }
        refresh()
    }
    
    //MARK: - Private methods
    @objc
    private func refresh() {
        newsViewModel?.refresh()
    }
    
    private func updateFor(state: NewsViewModelState?) {
        switch state {
        case .failure(let error):
            errorLabel.set(with: error)
        case .noItems(let message):
            errorLabel.text = ""
            emptyMessageLabel.text = message
            emptyMessageLabel.isHidden = false
            items = []
            tableView.reloadData()
        case .items(let items):
            errorLabel.text = ""
            emptyMessageLabel.isHidden = true
            self.items = items
            tableView.reloadData()
        case nil:
            break
        }
    }
    
    @IBAction func markAsReadAction(_ sender: Any) {
        newsViewModel?.markAsRead()
    }
}

//MARK: - UITableViewDataSource
extension ArticlesViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ArticlesTableViewCell", for: indexPath) as! ArticlesTableViewCell
        let article = items[indexPath.row]
        cell.set(
            author: article.author,
            publishedAt: article.publishedAt,
            title: article.title,
            description: article.description,
            imageURL: article.imageURL,
            isRead: article.isRead)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension ArticlesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let url = items[indexPath.row].url {
            newsViewModel?.markAsRead(article: url)
            
            let config = SFSafariViewController.Configuration()
            config.entersReaderIfAvailable = true

            let vc = SFSafariViewController(url: url, configuration: config)
            present(vc, animated: true)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

private extension ArticlesViewController.Mode {
    var title : String? {
      switch self {
      case .channel(let channel):   return channel.name
      case .enabledChannels:        return NSLocalizedString("All News", comment: "")
      }
    }
}
