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
import RxSwift
import RxCocoa

class NewsSearchViewController: UIViewController {
    // MARK: - Properties
    private let searchVC = UISearchController(searchResultsController: nil)
    private var newsViewModel: SearchableNewsViewModel = DefaultSearchableNewsViewModel()
    private var items: [NewsViewModelState.Item] = []
    private let activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var errorLabel: ErrorLabel!
    @IBOutlet private weak var emptyMessageLabel: UILabel!
    //Rx
    private let disposeBag = DisposeBag()
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
            self?.configure(withLoadingState: isLoading)
        }
        newsViewModel.onChangeState = { [weak self] (state) in
            self?.configure(withState: state)
        }
        //Rx
        searchVC.searchBar.rx.text.orEmpty
            .debug("searchBar.text", trimOutput: false)
            .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .flatMapLatest({ [weak self] keywords -> Single<NewsViewModelState> in
                guard let self = self else { return Single.error(CommonError.invalidState) }
                self.configure(withLoadingState: true)
                return self.newsViewModel.searchArticles(withKeywords: keywords)
            })
            .observeOn(MainScheduler.instance)
//            .trackActivity({ [weak self] (isLoading) in
//                self?.configure(withLoadingState: isLoading)
//            })
            .subscribe(onNext: { [weak self] state in
                self?.configure(withState: state)
                self?.configure(withLoadingState: false)
            })
            .disposed(by: disposeBag)
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
    
    private func configure(withState state: NewsViewModelState) {
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
        }
    }
    
    private func configure(withLoadingState isLoading: Bool) {
        if isLoading {
            tableView.tableHeaderView = self.activityIndicator
            tableView.reloadData()
            activityIndicator.startAnimating()
        } else {
            tableView.tableHeaderView = UIView()
            tableView.reloadData()
            activityIndicator.stopAnimating()
        }
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
