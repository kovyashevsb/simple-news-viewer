//
//  NewsSearchViewController.swift
//  SimpleNewsViewer
//
//  Created by Sergey on 05/06/2020.
//  Copyright © 2020 Sergey. All rights reserved.
//

import UIKit
import SafariServices
import Typist

class NewsSearchViewController: UIViewController {
    // MARK: - Properties
    private let searchVC = UISearchController(searchResultsController: nil)
    private var newsViewModel: SearchableNewsViewModel = DefaultSearchableNewsViewModel()
    private var items: [NewsViewModelState.Item] = []
    private let activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var errorLabel: ErrorLabel!
    @IBOutlet private weak var emptyMessageLabel: UILabel!
    
    // MARK: - Lifecycle
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        navigationController?.tabBarItem.title = NSLocalizedString("Search", comment: "")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Search", comment: "")
        
        configureKeyboard()
        
        searchVC.searchBar.delegate = self
        searchVC.obscuresBackgroundDuringPresentation = false
        searchVC.hidesNavigationBarDuringPresentation = false
        searchVC.searchBar.placeholder = NSLocalizedString("Type something here to search", comment: "")
        navigationItem.searchController = searchVC
        navigationItem.hidesSearchBarWhenScrolling = false
        
        let cellNib = UINib(nibName: "ArticlesTableViewCell", bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: "ArticlesTableViewCell")
        
        tableView.tableFooterView = UIView() //hide separators between empty cells
        
        newsViewModel.onLoading = { [weak self] (isLoading) in
            guard let self = self else { return }
            if isLoading {
                self.tableView.tableHeaderView = self.activityIndicator
                self.tableView.reloadData()
                self.activityIndicator.startAnimating()
            } else {
                self.tableView.tableHeaderView = UIView()
                self.tableView.reloadData()
                self.activityIndicator.stopAnimating()
            }
        }
        newsViewModel.onChangeState = { [weak self] (state) in
            guard let self = self else { return }
            switch state {
            case .failure(let error):
                self.errorLabel.set(with: error)
            case .noItems(let message):
                self.errorLabel.text = ""
                self.emptyMessageLabel.text = message
                self.emptyMessageLabel.isHidden = false
                self.items = []
                self.tableView.reloadData()
            case .items(let items):
                self.errorLabel.text = ""
                self.emptyMessageLabel.isHidden = true
                self.items = items
                self.tableView.reloadData()
            }
        }
    }
    
    //MARK: - Private methods
    private func configureKeyboard() {
        let keyboard = Typist.shared
        let insets = tableView.contentInset
        keyboard
            .on(event: .didShow) { (options) in
                let bottomInset = options.endFrame.height - (self.view.frame.height - self.tableView.frame.height - self.tableView.frame.origin.y)
                self.tableView.contentInset = UIEdgeInsets(top: insets.top, left: insets.left, bottom: bottomInset, right: insets.right)
            }
            .on(event: .didHide) { (options) in
                self.tableView.contentInset = insets
            }
            .start()
    }
}

//MARK: - UITableViewDataSource
extension NewsSearchViewController: UITableViewDataSource {
    
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
extension NewsSearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let url = items[indexPath.row].url {
            let config = SFSafariViewController.Configuration()
            config.entersReaderIfAvailable = true

            let vc = SFSafariViewController(url: url, configuration: config)
            present(vc, animated: true)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - UISearchBarDelegate
extension NewsSearchViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let keywords = searchBar.text {
            newsViewModel.searchNews(withKeywords: keywords)
        }
    }
}
