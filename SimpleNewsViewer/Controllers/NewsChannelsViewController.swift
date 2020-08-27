//
//  NewsChannelsTableViewController.swift
//  SimpleNewsViewer
//
//  Created by Sergey on 03/03/2020.
//  Copyright © 2020 Sergey. All rights reserved.
//

import UIKit
import CoreData

class NewsChannelsViewController: UIViewController {

    //MARK: - Properties
    private let newsModel: NewsModel = DefaultNewsModel.shared
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var errorLabel: ErrorLabel!
    private var refreshControl = UIRefreshControl()
    private lazy var fetchedResultsController = newsModel.channels(sortedBy: .name, ascending: true)

    //MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Channels", comment: "")
        
        refreshControl.addTarget(self, action: #selector(fetchAllChannels), for: .valueChanged)
        tableView.refreshControl = refreshControl
        tableView.tableFooterView = UIView() //hide separators between empty cells
        
        fetchedResultsController.delegate = self
        loadSavedData()
        fetchAllChannels()
    }
    
    //MARK: - Actions
    @IBAction func doneButtonAction(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - UITableViewDataSource
extension NewsChannelsViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections?.first
        return sectionInfo?.numberOfObjects ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NewsChannelTableViewCell", for: indexPath) as! NewsChannelTableViewCell
        
        let channel = fetchedResultsController.object(at: indexPath)
        
        cell.set(name: channel.name,
                 description: channel.about,
                 isOn: channel.isEnabled) { [weak self] (isOn) in
                    self?.newsModel.set(channel: channel, enabled: isOn)
        }
        
        return cell
    }
}

//MARK: - private methods
private extension NewsChannelsViewController {
    @objc
    func fetchAllChannels() {
        if !refreshControl.isRefreshing {
            refreshControl.beginRefreshing()
        }
        newsModel.fetchAllChannels { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                self.errorLabel.text = ""
            case .failure(let error):
                self.errorLabel.set(with: error)
            }
            self.refreshControl.endRefreshing()
        }
    }
    
    func loadSavedData() {
        do {
            try fetchedResultsController.performFetch()
            tableView.reloadData()
        } catch {
            print("NewsChannelsViewController failed to fetch")
        }
    }
}

//MARK: -
extension NewsChannelsViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.reloadData()
    }
}

